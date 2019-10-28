package com.noop.server;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.Map;
import org.apache.http.Header;
import org.apache.http.HttpEntity;
import org.apache.http.HttpResponse;
import org.apache.http.client.ClientProtocolException;
import org.apache.http.client.HttpClient;
import org.apache.http.client.ResponseHandler;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.client.methods.HttpPost;
import org.apache.http.entity.StringEntity;
import org.apache.http.impl.client.CloseableHttpClient;
import org.apache.http.impl.client.HttpClients;
import org.apache.http.util.EntityUtils;
import org.apache.log4j.Logger;
import com.noop.function.Handler;
import com.noop.model.AWSErrorMessage;
import com.noop.model.AWSLambdaRequest;
import com.noop.model.Response;

public class App {

    final static Logger logger = Logger.getLogger(App.class);

    public static void main(String[] args) {
        System.out.println("EIM: " + System.nanoTime());
        String serverAddress = System.getenv("AWS_LAMBDA_RUNTIME_API");

        Handler handler = new com.noop.function.Handler();
        CloseableHttpClient httpclient = HttpClients.createDefault();
        String apiAddress = "http://" + serverAddress;
        String requestUrl = apiAddress + "/2018-06-01/runtime/invocation/next";

        do {
            try {
                AWSLambdaRequest req = getNextRequest(httpclient, requestUrl);
                String reqID = req.getHeaders().get("Lambda-Runtime-Aws-Request-Id");

                String responseUrl = apiAddress + "/runtime/invocation/" + reqID + "/response";
                String invocationErrorUrl = apiAddress + "/runtime/invocation/" + reqID + "/error";

                if (req.getStatusCode() >= 200 && req.getStatusCode() < 300) {
                    Response res = handler.Handle(req);
                    if (res.getStatusCode() >= 200 && res.getStatusCode() < 300) {
                        // Response OK
                        Response successRes = sendResponse(httpclient, responseUrl, res.getBody(),
                                res.getHeaders());
                        if (successRes.getStatusCode() >= 200 && successRes.getStatusCode() < 300) {
                            String message = "Req [" + reqID + "] successfully processed";
                            logger.info(message);
                        } else {
                            String message = "Cannot send invocation response, due to ["
                                    + successRes.getBody() + "]";
                            logger.error(message);
                        }
                    } else {
                        // Invocation error
                    }
                } else {
                    // Invocation error

                }
            } catch (IOException e) {
                String message = "Cannot process next request";
                logger.error(message, e);
            }
        } while (true);

    }

    public static Response sendErrorResponse(HttpClient client, String url, AWSErrorMessage payload)
            throws ClientProtocolException, IOException {
        HttpPost httpost = new HttpPost(url);
        
        httpost.setEntity(new StringEntity(payload.toString(), StandardCharsets.UTF_8));

        return client.execute(httpost, new ResponseHandler<Response>() {

            @Override
            public Response handleResponse(HttpResponse response) {
                int status = response.getStatusLine().getStatusCode();
                HttpEntity entity = response.getEntity();
                String payload;
                try {
                    payload = getPayload(entity);
                } catch (IOException e) {
                    payload = e.getMessage();
                }
                Response res = new Response();
                res.setBody(payload);
                res.setStatusCode(status);
                return res;
            }

            private String getPayload(HttpEntity entity) throws IOException {
                String payload = "";
                if (entity != null) {
                    payload = EntityUtils.toString(entity);
                }
                return payload;
            }

        });
    }

    public static Response sendResponse(HttpClient client, String url, String payload,
            Map<String, String> headers) throws ClientProtocolException, IOException {
        HttpPost httpost = new HttpPost(url);
        for (String name : headers.keySet()) {
            httpost.addHeader(name, headers.get(name));
        }
        httpost.setEntity(new StringEntity(payload, StandardCharsets.UTF_8));

        return client.execute(httpost, new ResponseHandler<Response>() {

            @Override
            public Response handleResponse(HttpResponse response) {
                int status = response.getStatusLine().getStatusCode();
                HttpEntity entity = response.getEntity();
                String payload;
                try {
                    payload = getPayload(entity);
                } catch (IOException e) {
                    payload = e.getMessage();
                }
                Response res = new Response();
                res.setBody(payload);
                res.setStatusCode(status);
                return res;
            }

            private String getPayload(HttpEntity entity) throws IOException {
                String payload = "";
                if (entity != null) {
                    payload = EntityUtils.toString(entity);
                }
                return payload;
            }

        });
    }

    public static AWSLambdaRequest getNextRequest(HttpClient client, String url)
            throws ClientProtocolException, IOException {
        HttpGet httpget = new HttpGet(url);

        return client.execute(httpget, new ResponseHandler<AWSLambdaRequest>() {

            @Override
            public AWSLambdaRequest handleResponse(HttpResponse response) {
                int status = response.getStatusLine().getStatusCode();
                HttpEntity entity = response.getEntity();
                Map<String, String> headers = new HashMap<String, String>();
                for (Header header : response.getAllHeaders()) {
                    headers.put(header.getName(), header.getValue());
                }
                String payload;
                try {
                    payload = getPayload(entity);
                } catch (IOException e) {
                    status = 500;
                    payload = e.getMessage();
                }
                return new AWSLambdaRequest(status, payload, headers);
            }

            private String getPayload(HttpEntity entity) throws IOException {
                String payload = "";
                if (entity != null) {
                    payload = EntityUtils.toString(entity);
                }
                return payload;
            }

        });
    }

}
