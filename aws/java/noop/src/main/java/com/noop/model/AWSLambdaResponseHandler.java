package com.noop.model;

import java.io.IOException;
import org.apache.http.HttpEntity;
import org.apache.http.HttpResponse;
import org.apache.http.client.ResponseHandler;
import org.apache.http.util.EntityUtils;

public class AWSLambdaResponseHandler implements ResponseHandler<GenericResponse> {

    @Override
    public GenericResponse handleResponse(HttpResponse response) {
        int status = response.getStatusLine().getStatusCode();
        HttpEntity entity = response.getEntity();
        String payload;
        try {
            payload = getPayload(entity);
        } catch (IOException e) {
            payload = e.getMessage();
        }
        GenericResponse res = new GenericResponse();
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

}
