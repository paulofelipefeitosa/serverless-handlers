package com.noopclassloader.function;

import java.io.IOException;
import com.noopclassloader.model.IRequest;
import com.noopclassloader.model.IResponse;
import com.noopclassloader.model.Response;

public class Handler implements com.noopclassloader.model.IHandler {

    private EagerClassLoader classLoader;

    public Handler(String jarFilePath) {
        try {
            this.classLoader = new EagerClassLoader(jarFilePath);
        } catch (IOException e) {
            System.err.println("Cannot create EagerClassLoader");
            System.err.println(e.getMessage());
            e.printStackTrace();
        }
    }

    public IResponse Handle(IRequest req) {
        System.out.println("T4: " + System.nanoTime());
        Response res = new Response();
        try {
            this.classLoader.loadJarClasses();
        } catch (Throwable e) {
            res.setStatusCode(500);
            res.setBody(e.toString());
            e.printStackTrace();
        }
        System.out.println("T6: " + System.nanoTime());
        return res;
    }

}
