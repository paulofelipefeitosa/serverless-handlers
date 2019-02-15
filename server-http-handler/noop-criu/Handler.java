public class Handler implements IHandler {

    public IResponse Handle(IRequest req) {
        System.out.println("T4: " + System.currentTimeMillis());
        Response res = new Response();
        System.out.println("T6: " + System.currentTimeMillis());
        return res;
    }

}