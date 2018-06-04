module zeta.testmodule;

class LexerState {
	def text;
	def position;
	def file;
	def appender;

	function this(file, text) {
		this.file = file;
		this.text = text;
	}

	@property function empty() {
		return position >= text.length;
	}

	@property function length() {
		return text.length - position;
	}

	@property function front() {
		return text[position];
	}

	function popFront() {
		return text[position++];
	}

	function frontN(amount) {
		return text[position..min(position+amount, $)];
	}

	function popFrontN(amount) {
		def result = this.frontN(amount);
		position += result.length;
		return result;
	}

	@property function location() {
		return SourceLocation.fromBuffer(text, position, file);
	}

	function pushToken(token) {
		this.tokenBuffer.put(token);
	}

	@property function tokens() {
		return this.tokenBuffer.data;
	}
}