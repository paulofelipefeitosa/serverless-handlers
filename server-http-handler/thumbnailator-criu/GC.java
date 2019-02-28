public class GC {
	public static native void force();

	static {
		System.load(System.getProperty("jvmtilib"));
	}
}
