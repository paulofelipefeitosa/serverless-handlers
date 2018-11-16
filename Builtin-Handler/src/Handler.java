import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.lang.management.ManagementFactory;

public class Handler {
    public static void main(String[] args) throws IOException {
        long jvmStartTime = ManagementFactory.getRuntimeMXBean().getStartTime();
        long readyTime = System.currentTimeMillis();
        BufferedReader br = new BufferedReader(new InputStreamReader(System.in));
        String line = null;
        StringBuilder builder = new StringBuilder();
        do {
            line = br.readLine();
            builder.append((line != null) ? line + System.lineSeparator() : "");
        } while (line != null);
        long readyToProcessTime = System.currentTimeMillis();
        builder.append("JVMStartTime: " + jvmStartTime + System.lineSeparator());
        builder.append("ReadyTime: " + readyTime + System.lineSeparator());
        builder.append("ReadyToProcessTime: " + readyToProcessTime + System.lineSeparator());
        System.out.println(builder.toString());
        br.close();
    }
}
