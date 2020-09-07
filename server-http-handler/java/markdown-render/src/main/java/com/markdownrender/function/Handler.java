package com.markdownrender.function;

import com.markdownrender.model.IRequest;
import com.markdownrender.model.IResponse;
import com.markdownrender.model.Response;
import org.commonmark.node.Node;
import org.commonmark.parser.Parser;
import org.commonmark.renderer.html.HtmlRenderer;

public class Handler implements com.markdownrender.model.IHandler {

    public static final String WARM_REQUEST_HEADER_KEY = "X-warm-request";

    public IResponse Handle(IRequest req) {
        boolean isWarmReq = req.getHeaders().containsKey(WARM_REQUEST_HEADER_KEY);
        if (!isWarmReq) {
            System.out.println("T4: " + System.nanoTime());
        }

        String markdown = req.getBody();

        Parser parser = Parser.builder().build();
        Node document = parser.parse(markdown);
        HtmlRenderer renderer = HtmlRenderer.builder().build();
        String html = renderer.render(document);

        Response res = new Response();
        res.setBody(html);
        res.setContentType("text/html");

        if (!isWarmReq) {
            System.out.println("T6: " + System.nanoTime());
        }

        return res;
    }

}
