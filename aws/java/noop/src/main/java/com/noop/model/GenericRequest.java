package com.noop.model;

import java.util.Map;

public class GenericRequest {
    String data;
    Map<String, String> headers;
    
    public GenericRequest(String data, Map<String, String> headers) {
        this.data = data;
        this.headers = headers;
    }

    public String getPayload() {
        return data;
    }

    public Map<String, String> getHeaders() {
        return headers;
    }
}
