package com.noop.model;

import java.util.Map;

public class AWSLambdaRequest {
    int statusCode;
    String payload;
    Map<String, String> headers;

    public AWSLambdaRequest(int statusCode, String payload, Map<String, String> headers) {
        this.statusCode = statusCode;
        this.payload = payload;
        this.headers = headers;
    }

    public int getStatusCode() {
        return statusCode;
    }

    public String getPayload() {
        return payload;
    }

    public Map<String, String> getHeaders() {
        return headers;
    }

}
