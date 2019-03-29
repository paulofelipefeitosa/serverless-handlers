class Nothing {

    public static void main(String[] args) {
		System.out.println("[" + System.nanoTime() + "] Oi");
		GC.force();
    }

}
