package pt.ulisboa.tecnico.cnv.javassist.tools;

import java.util.List;

import javassist.CannotCompileException;
import javassist.CtBehavior;

import java.io.FileWriter;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.HashMap;
import java.util.Map;

public class ICount extends CodeDumper {

    /**
     * Number of executed basic blocks.
     */
    private static long nblocks = 0;

    /**
     * Number of executed methods.
     */
    private static long nmethods = 0;

    /**
     * Number of executed instructions.
     */
    private static long ninsts = 0;

    // Thread-local statistics
    private static final ThreadLocal<Long> nblocksThread = ThreadLocal.withInitial(() -> 0L);
    private static final ThreadLocal<Long> nmethodsThread = ThreadLocal.withInitial(() -> 0L);
    private static final ThreadLocal<Long> ninstsThread = ThreadLocal.withInitial(() -> 0L);


    public ICount(List<String> packageNameList, String writeDestination) {
        super(packageNameList, writeDestination);
    }

    public static void incBasicBlock(int position, int length) {
        // Global stats
        nblocks++;
        ninsts += length;

        // Per-thread stats
        nblocksThread.set(nblocksThread.get() + 1);
        ninstsThread.set(ninstsThread.get() + length);
    }

    public static void incBehavior(String name) {
        // Global stats
        nmethods++;

        // Per-thread stats
        nmethodsThread.set(nmethodsThread.get() + 1);
    }

    public static void printStatistics() {
        System.out.println(String.format("[%s] Number of executed methods: %s", ICount.class.getSimpleName(), nmethods));
        System.out.println(String.format("[%s] Number of executed basic blocks: %s", ICount.class.getSimpleName(), nblocks));
        System.out.println(String.format("[%s] Number of executed instructions: %s", ICount.class.getSimpleName(), ninsts));
    }

    public static void printThreadStatistics() {
        System.out.println(String.format("[%s-Thread] Methods: %s", Thread.currentThread().getName(), nmethodsThread.get()));
        System.out.println(String.format("[%s-Thread] Basic blocks: %s", Thread.currentThread().getName(), nblocksThread.get()));
        System.out.println(String.format("[%s-Thread] Instructions: %s", Thread.currentThread().getName(), ninstsThread.get()));
    }

    @Override
    protected void transform(CtBehavior behavior) throws Exception {
        super.transform(behavior);
        behavior.insertAfter(String.format("%s.incBehavior(\"%s\");", ICount.class.getName(), behavior.getLongName()));

        if (behavior.getName().equals("main")) {
            behavior.insertAfter(String.format("%s.printStatistics();", ICount.class.getName()));
            behavior.insertAfter(String.format("%s.writeStatisticsToFile();", ICount.class.getName()));
        }

        if (behavior.getName().equals("handleWorkload")) {
            behavior.insertAfter(String.format("%s.printThreadStatistics();", ICount.class.getName()));
            behavior.insertAfter(String.format("%s.writeThreadStatisticsToFile();", ICount.class.getName()));
            behavior.insertAfter(String.format("%s.resetThreadStatistics();", ICount.class.getName()));
        }
    }

    @Override
    protected void transform(BasicBlock block) throws CannotCompileException {
        super.transform(block);
        block.behavior.insertAt(block.line, String.format("%s.incBasicBlock(%s, %s);", ICount.class.getName(), block.getPosition(), block.getLength()));
    }

    public static void resetThreadStatistics() {
        nblocksThread.set(0L);
        nmethodsThread.set(0L);
        ninstsThread.set(0L);
    }

    // Automatically writes to "global_stats.txt"
    public static void writeStatisticsToFile() {
        String filename = "global_stats.txt";
        try (PrintWriter writer = new PrintWriter(new FileWriter(filename, true))) {
            writer.println("=== Global Statistics ===");
            writer.println("Methods: " + nmethods);
            writer.println("Basic blocks: " + nblocks);
            writer.println("Instructions: " + ninsts);
            writer.println();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    // Automatically writes per-thread stats to "thread_stats_<thread-name>.txt"
    public static void writeThreadStatisticsToFile() {
        String threadName = Thread.currentThread().getName().replaceAll("[^a-zA-Z0-9.-]", "_");
        String filename = "thread_stats_" + threadName + ".txt";
        try (PrintWriter writer = new PrintWriter(new FileWriter(filename, true))) {
            writer.println("=== Thread Statistics (Thread: " + threadName + ") ===");
            writer.println("Methods: " + nmethodsThread.get());
            writer.println("Basic blocks: " + nblocksThread.get());
            writer.println("Instructions: " + ninstsThread.get());
            writer.println();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

}
