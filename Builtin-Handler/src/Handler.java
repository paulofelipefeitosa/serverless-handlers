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
        builder.append("{\"input\":");
        try (BufferedReader in = new BufferedReader(new InputStreamReader(System.in));
                Stream<String> stream = in.lines()) {
            builder.append(stream.collect(Collectors.joining(System.lineSeparator())));
            builder.append(",");
        }
        long readyToProcessTime = System.currentTimeMillis();

        BufferedReader br = new BufferedReader(new InputStreamReader(System.in));
        // Read docker run timestamps

        File file = new File("timestamps.ts");
        br = new BufferedReader(new FileReader(file));
        String line = null;
        
        builder.append("\"timestamps\":{");
        do {
            line = br.readLine();
            if(line != null) {
                String[] array = line.split(":");
                builder.append("\"" + array[0] + "\":");
                builder.append(array[1] + ",");
            }
        } while (line != null);

        builder.append("\"JVMStartTime\": " + jvmStartTime + ",");
        builder.append("\"ReadyTime\": " + readyTime + ",");
        builder.append("\"ReadyToProcessTime\": " + readyToProcessTime);
        builder.append("}}");
        br.close();
        System.out.println(builder.toString());
    }
}
