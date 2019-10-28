package com.noop.function;

import com.noop.model.GenericRequest;
import com.noop.model.GenericResponse;

public class Handler {

    public static final String WARM_REQUEST_HEADER_KEY = "X-warm-request";

    public GenericResponse Handle(GenericRequest req) {
        boolean isWarmReq = req.getHeaders().containsKey(WARM_REQUEST_HEADER_KEY);
        if (!isWarmReq) {
            System.out.println("T4: " + System.nanoTime());
        }
        GenericResponse res = new GenericResponse();
        if (!isWarmReq) {
            System.out.println("T6: " + System.nanoTime());
        }
        
        return res;
    }

}
