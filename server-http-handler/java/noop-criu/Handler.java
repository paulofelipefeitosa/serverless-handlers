public class Handler implements IHandler {

    public static final String WARM_REQUEST_HEADER_KEY = "X-warm-request";

    public IResponse Handle(IRequest req) {
        boolean isWarmRequest = req.getHeaders().containsKey(WARM_REQUEST_HEADER_KEY);
        if (!isWarmRequest) {
            System.out.println("T4: " + System.nanoTime());
        }
        Response res = new Response();
        if (!isWarmRequest) {
            System.out.println("T6: " + System.nanoTime());
        }
        return res;
    }

}
