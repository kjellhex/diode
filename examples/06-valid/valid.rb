require 'date'
require 'time'

module Valid

	# return the input without any characters not in the approved charset
	def self.filter(input, charset)
		validchars = charset.chars
		input.chars.find_all{|c| validchars.include?(c) }.join("")
	end

	# validate the input according to the scheme. Some schemes support arguments.
	#   Valid.input(s, :digits, 6) ensures the string contains only digits and is not longer than 6 digits
	#   Valid.input(s, :digits, 7..9) ensures the string has a length of 7,8 or 9 digits only
	#   Valid.input(s, :digits, 6..6) ensures the string has a length of exactly 6 digits only
	#   Valid.input(s, :text, 35) ensures the string is less than 36 chars long (any chars allowed)
	#   Valid.input(s, :alpha, 12) ensures the string is less than 12 chars long and contains only letters (a..zA..Z)
	#   Valid.input(s, "1234567890,.$-", 5..8) allows a formatted dollar amount using custom charset
	#   Valid.input(s, :date) checks for exactly 8 digits that make a valid date
	#   Valid.input(s, :current) checks for exactly 8 digits that make a valid date within a few years of today (custom method added to Valid)
	def self.input(input, scheme, *args)
		return(custom_charset(input, scheme, *args)) if scheme.is_a?(String)
		return(self.send(scheme, input, *args)) if self.respond_to?(scheme)
		raise("unknown validation scheme=#{scheme}")
	end

	# return true if the input size is within the specified range
	def self.check_size(input, range)
		raise("range must be am Integer or a Range") unless range.is_a?(Integer) or (range.is_a?(Range) and range.max.is_a?(Integer))
		range = 0..range if range.is_a?(Integer)
		len = input.to_s.size()
		range.include?(len)
	end

	# check that the input contains only allowed characters, and is the right size
	def self.custom_charset(input, charset, range)
		validchars = charset.chars
		input.chars.reject{ |c| validchars.include?(c) }.empty? and check_size(input, range)
	end

	# check the input is only digits of a certain length
	def self.digits(input, range)
		validchars = ("0".."9").to_a()
		input.chars.reject{ |c| validchars.include?(c) }.empty? and check_size(input, range)
	end

	# check the input is only numbers of a certain length, allowing comma, decimal point, minus
	def self.numeric(input, range)
		validchars = ("0".."9").to_a() + "-.,".chars()  # eg. 1,000.00
		input.chars.reject{ |c| validchars.include?(c) }.empty? and check_size(input, range)
	end

	def self.boolean(input)
		["true", "false", ""].include?(input.to_s.downcase())
	end

	# check the input is only letters of a certain length
	def self.alpha(input, range)
		validchars = ("a".."z").to_a + ("A".."Z").to_a  # Roger
		input.chars.reject{ |c| validchars.include?(c) }.empty? and check_size(input, range)
	end

	# check the input is only letters of a certain length
	def self.words(input, range)
		validchars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a() + "_ .,;:/!-'".chars # "St. Yve's, 26th March 8:10"
		input.chars.reject{ |c| validchars.include?(c) }.empty? and check_size(input, range)
	end

	# check the input is alphanumeric of a certain length
	def self.alphanum(input, range)
		validchars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a() + ["-", "_"] # Roger4
		input.chars.reject{ |c| validchars.include?(c) }.empty? and check_size(input, range)
	end

	# check the input is a valid name or label (one short line of text)
	def self.name(input, range)
		validchars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a() + "!@# $%^&*()-_+=[]{};:'\".,/?|~".chars # Roger O'Doom-4
		input.chars.reject{ |c| validchars.include?(c) }.empty? and check_size(input, range)
	end

	# check the input is ascii text of a certain length
	def self.text(input, range)
		validchars = (" ".."~").to_a + "\n\t\r".chars()  # "Hi! \nHow are you?"
		input.chars.reject{ |c| validchars.include?(c) }.empty? and check_size(input, range)
	end

	# check the input is a valid date
	def self.date(input)
		clean = input.dup
		clean.gsub!("-","") if clean.size == 10
		return(false) unless self.digits(clean, 8..8)
		begin
			d = Date.parse(clean)
		rescue ArgumentError
			return(false)
		end
		true
	end

	# check the input is a valid time
	def self.time(input)
		begin
			t = Time.parse(input)
		rescue ArgumentError
			return(false)
		end
		true
	end
end
