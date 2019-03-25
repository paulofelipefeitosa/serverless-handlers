class Nothing {

    public static void main(String[] args) {
		System.out.println("[" + System.currentTimeMillis() * 1000000 + "] Oi");
		GC.force();
    }

}
