import java.util.stream.LongStream;

public class Hello {
    public static void main(String[] args) {
        long sum = LongStream.rangeClosed(1, 100).parallel().map(x -> x * x).sum();
        System.out.println("sum of squares 1..100 = " + sum);
        // A container-aware JVM sizes itself from the job's cgroup, not the whole node.
        int cpus = Runtime.getRuntime().availableProcessors();
        String alloc = System.getenv("SLURM_CPUS_PER_TASK");
        System.out.println("availableProcessors matches job: "
                + (alloc == null || Integer.parseInt(alloc) == cpus ? "yes" : "no (" + cpus + " vs " + alloc + ")"));
        long maxHeapMB = Runtime.getRuntime().maxMemory() >> 20;
        System.out.println("max heap within 2G job limit: " + (maxHeapMB <= 2048 ? "yes" : "no (" + maxHeapMB + " MB: the JVM does not see the job memory limit)"));
    }
}
