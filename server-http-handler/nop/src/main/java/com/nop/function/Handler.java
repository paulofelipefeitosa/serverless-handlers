package com.nop.function;

import com.nop.model.IRequest;
import com.nop.model.IResponse;
import com.nop.model.Response;

public class Handler implements com.nop.model.IHandler {

	public IResponse Handle(IRequest req) {
		System.out.println("T4: " + System.currentTimeMillis());
		Response res = new Response();
		System.out.println("T6: " + System.currentTimeMillis());
		return res;
	}

}
