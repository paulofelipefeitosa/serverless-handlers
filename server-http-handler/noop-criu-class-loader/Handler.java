import java.io.IOException;

public class Handler implements IHandler {

    public static final String WARM_REQUEST_HEADER_KEY = "X-warm-request";

    private EagerClassLoader classLoader;
    private int reqs = 0;

    public Handler(String jarFilePath) throws IOException {
        this.classLoader = new EagerClassLoader(jarFilePath);
    }

    public IResponse Handle(IRequest req) {
        boolean isWarmReq = req.getHeaders().containsKey(WARM_REQUEST_HEADER_KEY);
        if (!isWarmReq) {
            System.out.println("T4: " + System.nanoTime());
        }
        Response res = new Response();
        String loadStats = "";
        if (this.reqs == 0) {
            try {
                loadStats = this.classLoader.loadJarClasses();
            } catch (Throwable e) {
                res.setStatusCode(500);
                res.setBody(e.toString());
                e.printStackTrace();
            }
        }
        if (!isWarmReq) {
            System.out.println("T6: " + System.nanoTime());
            if (this.reqs == 0) {
                System.out.println(loadStats);
            }
        }
        this.reqs++;
        return res;
    }

}
