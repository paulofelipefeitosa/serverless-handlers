package com.noop.function;

import com.noop.model.IRequest;
import com.noop.model.IResponse;
import com.noop.model.Response;

public class Handler implements com.noop.model.IHandler {

    public static final String WARM_REQUEST_HEADER_KEY = "X-warm-request";

    public IResponse Handle(IRequest req) {
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
