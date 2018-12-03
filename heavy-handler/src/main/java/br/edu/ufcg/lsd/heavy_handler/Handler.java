package br.edu.ufcg.lsd.heavy_handler;

import com.amazonaws.services.s3.AmazonS3;
import com.amazonaws.services.s3.AmazonS3ClientBuilder;
import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.lang.management.ManagementFactory;
import java.nio.file.Paths;
import java.util.stream.Collectors;
import java.util.stream.Stream;
import org.json.JSONObject;

public class Handler {
    public static void main(String[] args) throws IOException {
        long readyTime = System.currentTimeMillis();
        long jvmStartTime = ManagementFactory.getRuntimeMXBean().getStartTime();

        JSONObject response = getStdinInput();
        long readyToProcessTime = System.currentTimeMillis();

        JSONObject timestamps = getContainerTimestamps();

        String bucket_name = "teste";
        String file_path = "teste";
        String key_name = Paths.get(file_path).getFileName().toString();

        try {
            final AmazonS3 s3 = AmazonS3ClientBuilder.defaultClient();
            s3.putObject(bucket_name, key_name, new File(file_path));
        } catch (Exception e) {
        }

        timestamps.append("JVMStartTime", jvmStartTime);
        timestamps.append("ReadyTime", readyTime);
        timestamps.append("ReadyToProcessTime", readyToProcessTime);

        response.put("timestamps", timestamps);

        System.out.println(response.toString());
    }

    private static JSONObject getContainerTimestamps() throws IOException {
        File file = new File("timestamps.ts");
        BufferedReader br = new BufferedReader(new FileReader(file));

        JSONObject response = new JSONObject();
        String line = null;
        do {
            line = br.readLine();
            if (line != null) {
                String[] array = line.split(":");
                response.append(array[0], array[1]);
            }
        } while (line != null);
        br.close();
        return response;
    }

    private static JSONObject getStdinInput() throws IOException {
        JSONObject response = new JSONObject();
        try (BufferedReader in = new BufferedReader(new InputStreamReader(System.in));
                Stream<String> stream = in.lines()) {
            response.append("input", stream.collect(Collectors.joining(System.lineSeparator())));
        }
        return response;
    }
}
