package com.noop.function;

import com.noop.model.IRequest;
import com.noop.model.IResponse;
import com.noop.model.Response;

public class Handler implements com.noop.model.IHandler {

    public IResponse Handle(IRequest req) {
        System.out.println("T4: " + System.nanoTime());
        Response res = new Response();
        System.out.println("T6: " + System.nanoTime());
        return res;
    }

}
