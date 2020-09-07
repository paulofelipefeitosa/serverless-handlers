package com.markdown.function;

import com.markdown.model.IResponse;
import com.markdown.model.Request;
import junit.framework.TestCase;

import java.util.HashMap;
import java.util.Map;

public class HandlerTest extends TestCase {
    public void testHandle() {
        Handler handle = new Handler();
        Map<String, String> headers = new HashMap<String, String>();
        headers.put(Handler.WARM_REQUEST_HEADER_KEY, "Yes");
        Request req = new Request("This is *Sparta*", headers);
        IResponse res = handle.Handle(req);
        String actual = res.getBody();
        String expected = "<p>This is <em>Sparta</em></p>\n";
        assertEquals(actual, expected);
        assertEquals(res.getContentType(), "text/html");
    }
}
