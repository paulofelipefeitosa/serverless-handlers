package com.noop.model;

import java.io.IOException;
import java.util.HashMap;
import java.util.Map;
import org.apache.http.Header;
import org.apache.http.HttpEntity;
import org.apache.http.HttpResponse;
import org.apache.http.client.ClientProtocolException;
import org.apache.http.client.ResponseHandler;
import org.apache.http.util.EntityUtils;

public class AWSLambdaRequestResponseHandler implements ResponseHandler<AWSLambdaRequest> {

    @Override
    public AWSLambdaRequest handleResponse(HttpResponse response)
            throws ClientProtocolException, IOException {
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

}
