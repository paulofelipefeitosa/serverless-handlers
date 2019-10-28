package com.noop.model;

public class AWSErrorMessage {
    String errorMessage;
    String errorType;
    
    public AWSErrorMessage(String errorMessage, String errorType) {
        super();
        this.errorMessage = errorMessage;
        this.errorType = errorType;
    }

    public String getErrorMessage() {
        return errorMessage;
    }

    public String getErrorType() {
        return errorType;
    }

    @Override
    public String toString() {
        return "{\"errorMessage\": \"" + this.errorMessage + "\", \"errorType\": \"" + this.errorType + "\"}";
    }
    
}
