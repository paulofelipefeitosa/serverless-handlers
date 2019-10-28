package com.noop.function;

import com.noop.model.AWSLambdaRequest;
import com.noop.model.Response;

public class Handler {

    public static final String WARM_REQUEST_HEADER_KEY = "X-warm-request";

    public Response Handle(AWSLambdaRequest req) {
        boolean isWarmReq = req.getHeaders().containsKey(WARM_REQUEST_HEADER_KEY);
        if (!isWarmReq) {
            System.out.println("T4: " + System.nanoTime());
        }
        Response res = new Response();
        if (!isWarmReq) {
            System.out.println("T6: " + System.nanoTime());
        }
        
        return res;
    }

}
