package com.noop.server;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import org.apache.http.client.ClientProtocolException;
import org.apache.http.client.HttpClient;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.client.methods.HttpPost;
import org.apache.http.entity.StringEntity;
import org.apache.http.impl.client.CloseableHttpClient;
import org.apache.http.impl.client.HttpClients;
import org.apache.log4j.Logger;
import com.noop.function.Handler;
import com.noop.model.AWSErrorMessage;
import com.noop.model.AWSLambdaRequest;
import com.noop.model.AWSLambdaRequestResponseHandler;
import com.noop.model.AWSLambdaResponseHandler;
import com.noop.model.GenericResponse;

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

                String invocationErrorUrl = apiAddress + "/runtime/invocation/" + reqID + "/error";
                GenericResponse awsAPIRes;
                
                // Check get Request from AWS API Response
                if (req.getStatusCode() >= 200 && req.getStatusCode() < 300) {
                    String responseUrl = apiAddress + "/runtime/invocation/" + reqID + "/response";
                    GenericResponse functionRes = handler.Handle(req.getGenericRequest());

                    if (functionRes.getStatusCode() >= 200 && functionRes.getStatusCode() < 300) {
                        // Response OK
                        awsAPIRes = sendResponse(httpclient, responseUrl, functionRes);
                    } else {
                        // Invocation error
                        AWSErrorMessage payload =
                                new AWSErrorMessage(functionRes.getBody(), "InvalidEventDataException");
                        awsAPIRes = sendResponse(httpclient, invocationErrorUrl,
                                new GenericResponse(payload.toString()));
                    }

                } else {
                    // Invocation error
                    AWSErrorMessage payload =
                            new AWSErrorMessage(req.getPayload(), "GetNextRequestError");
                    awsAPIRes = sendResponse(httpclient, invocationErrorUrl,
                            new GenericResponse(payload.toString()));

                }
                
                // Check Invocation Response status
                if (awsAPIRes.getStatusCode() >= 200 && awsAPIRes.getStatusCode() < 300) {
                    String message = "Response to Request [" + reqID + "] was successfully sent to AWS API";
                    logger.info(message);
                } else {
                    String message = "Cannot send Response to Request [" + reqID + "] , due to [" + awsAPIRes.getBody() + "]";
                    logger.error(message);
                }
                
            } catch (IOException e) {
                String message = "Cannot process Get Next Request";
                logger.error(message, e);
            }
        } while (true);

    }

    private static GenericResponse sendResponse(HttpClient client, String url, GenericResponse res)
            throws ClientProtocolException, IOException {
        HttpPost httpost = new HttpPost(url);
        for (String name : res.getHeaders().keySet()) {
            httpost.addHeader(name, res.getHeader(name));
        }
        httpost.setEntity(new StringEntity(res.getBody(), StandardCharsets.UTF_8));

        return client.execute(httpost, new AWSLambdaResponseHandler());
    }

    private static AWSLambdaRequest getNextRequest(HttpClient client, String url)
            throws ClientProtocolException, IOException {
        HttpGet httpget = new HttpGet(url);
        return client.execute(httpget, new AWSLambdaRequestResponseHandler());
    }

}
