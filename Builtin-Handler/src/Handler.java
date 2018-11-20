import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.lang.management.ManagementFactory;

public class Handler {
    public static void main(String[] args) throws IOException {
        long readyTime = System.currentTimeMillis();
        long jvmStartTime = ManagementFactory.getRuntimeMXBean().getStartTime();
        
        BufferedReader br = new BufferedReader(new InputStreamReader(System.in));
        String line = null;
        StringBuilder builder = new StringBuilder();
        do {
            line = br.readLine();
            builder.append((line != null) ? line + System.lineSeparator() : "");
        } while (line != null);
        long readyToProcessTime = System.currentTimeMillis();
        br.close();
        
        // Read docker run timestamps
        File file = new File("timestamps.ts");
        br = new BufferedReader(new FileReader(file));
        line = null;
        do {
            line = br.readLine();
            builder.append((line != null) ? line + System.lineSeparator() : "");
        } while (line != null);
        
        builder.append("JVMStartTime: " + jvmStartTime + System.lineSeparator());
        builder.append("ReadyTime: " + readyTime + System.lineSeparator());
        builder.append("ReadyToProcessTime: " + readyToProcessTime + System.lineSeparator());
        br.close();
        System.out.println(builder.toString());
    }
}
