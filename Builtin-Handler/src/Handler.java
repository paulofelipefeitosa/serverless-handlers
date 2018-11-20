import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.lang.management.ManagementFactory;
import java.util.stream.Collectors;
import java.util.stream.Stream;

public class Handler {
    public static void main(String[] args) throws IOException {
        long readyTime = System.currentTimeMillis();
        long jvmStartTime = ManagementFactory.getRuntimeMXBean().getStartTime();

        StringBuilder builder = new StringBuilder();
        try (BufferedReader in = new BufferedReader(new InputStreamReader(System.in));
                Stream<String> stream = in.lines()) {
            builder.append(stream.collect(Collectors.joining(System.lineSeparator())));
            builder.append(System.lineSeparator());
        }
        long readyToProcessTime = System.currentTimeMillis();

        BufferedReader br = new BufferedReader(new InputStreamReader(System.in));
        // Read docker run timestamps

        File file = new File("timestamps.ts");
        br = new BufferedReader(new FileReader(file));
        String line = null;
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
