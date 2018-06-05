module zeta.testmodule;

function main() {
	def buffer = "";
	for(def i = 0; i < 10; i++) {
		buffer ~= i;
		buffer ~= " ";
	}
	return buffer;
}