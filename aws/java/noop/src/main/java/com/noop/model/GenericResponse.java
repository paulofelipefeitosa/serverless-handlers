// Copyright (c) OpenFaaS Author(s) 2018. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for full license
// information.

package com.noop.model;

import java.util.HashMap;
import java.util.Map;

public class GenericResponse {

    private int statusCode = 200;
    private String body;
    private Map<String, String> headers;

    public GenericResponse() {
        this.body = "";
        this.headers = new HashMap<String, String>();
    }

    public GenericResponse(String body) {
        super();
        this.body = body;
        this.headers = new HashMap<String, String>();
    }

    public int getStatusCode() {
        return statusCode;
    }

    public void setStatusCode(int statusCode) {
        this.statusCode = statusCode;
    }

    public Map<String, String> getHeaders() {
        return this.headers;
    }

    public void setHeader(String key, String value) {
        if (value == null) {
            if (this.headers.containsKey(key)) {
                this.headers.remove(key);
                return;
            }
        }
        this.headers.put(key, value);
    }

    public String getHeader(String key) {
        if (!this.headers.containsKey(key)) {
            return null;
        }

        return this.headers.get(key);
    }

    public void setBody(String body) {
        this.body = body;
    }

    public String getBody() {
        return this.body;
    }
}
