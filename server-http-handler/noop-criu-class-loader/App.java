
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.InetSocketAddress;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.Executors;
import com.sun.net.httpserver.Headers;
import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpHandler;
import com.sun.net.httpserver.HttpServer;

public class App {

    private static InvokeHandler invokeHandler;

    public static void main(String[] args) throws Exception {
        System.out.println("EIM: " + System.nanoTime());
        int port = 9000;

        IHandler handler = new Handler(args[0]);

        InetSocketAddress addr = new InetSocketAddress(port);
        HttpServer server = HttpServer.create(addr, 0);
        invokeHandler = new InvokeHandler(handler);

        server.createContext("/", invokeHandler);
        server.createContext("/ping").setHandler(App::handlePing);
        server.createContext("/gc").setHandler(App::handleGC);
        server.setExecutor(Executors.newSingleThreadExecutor());
        server.start();
        System.out.println("EFM: " + System.nanoTime());
    }

    private static void handleGC(HttpExchange exchange) throws IOException {
        try {
            GC.force();
            exchange.sendResponseHeaders(200, 0);
        } finally {
            exchange.close();
        }
    }

    private static void handlePing(HttpExchange exchange) throws IOException {
        try {
            invokeHandler.handle(exchange);
        } finally {
        }
    }

    static class InvokeHandler implements HttpHandler {
        IHandler handler;

        private InvokeHandler(IHandler handler) {
            this.handler = handler;
        }

        @Override
        public void handle(HttpExchange t) throws IOException {
            String requestBody = "";
            String method = t.getRequestMethod();

            if (method.equalsIgnoreCase("POST")) {
                InputStream inputStream = t.getRequestBody();
                ByteArrayOutputStream result = new ByteArrayOutputStream();
                byte[] buffer = new byte[1024];
                int length;
                while ((length = inputStream.read(buffer)) != -1) {
                    result.write(buffer, 0, length);
                }
                inputStream.close();
                // StandardCharsets.UTF_8.name() > JDK 7
                requestBody = result.toString("UTF-8");
            }

            Headers reqHeaders = t.getRequestHeaders();
            Map<String, String> reqHeadersMap = new HashMap<String, String>();

            for (Map.Entry<String, java.util.List<String>> header : reqHeaders.entrySet()) {
                java.util.List<String> headerValues = header.getValue();
                if (headerValues.size() > 0) {
                    reqHeadersMap.put(header.getKey(), headerValues.get(0));
                }
            }

            IRequest req = new Request(requestBody, reqHeadersMap, t.getRequestURI().getRawQuery(),
                    t.getRequestURI().getPath());

            IResponse res = this.handler.Handle(req);

            String response = res.getBody();
            byte[] bytesOut = response.getBytes("UTF-8");

            Headers responseHeaders = t.getResponseHeaders();
            String contentType = res.getContentType();
            if (contentType.length() > 0) {
                responseHeaders.set("Content-Type", contentType);
            }

            for (Map.Entry<String, String> entry : res.getHeaders().entrySet()) {
                responseHeaders.set(entry.getKey(), entry.getValue());
            }

            t.sendResponseHeaders(res.getStatusCode(), bytesOut.length);

            OutputStream os = t.getResponseBody();
            os.write(bytesOut);
            os.close();

            t.close();
        }
    }
}
