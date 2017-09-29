Token = Struct.new(:type, :data, :src, :row, :col, :scope)
Rule = Struct.new(:name, :regex, :scope)

rules = {
	default: [
		Rule.new(:period1, /\.\s*/, :othermode),
		Rule.new(:word1, /[^\.]+/)
	],
	othermode: [
		Rule.new(:comma2, /\,\s*/, :otherothermode),
		Rule.new(:period2, /\.\s*/, :<),
		Rule.new(:word2, /[^\,]+/)
	],
	otherothermode: [
		Rule.new(:comma3, /\,\s*/),
		Rule.new(:period3, /\.\s*/, :<),
		Rule.new(:word3, /[^\,\.]+/)
	]
}

def tokenize s, src, rules=nil
	return [[], false] if [s, src, rules].any?{|x| x.nil? or x.empty? }
	default_rule = Rule.new(:unknown, /./)
	rules = rules || { default: [rule("CHARACTER", /./)] }
	rules = { default: rules } if rules.is_a?(Array)
	out, scope = [], []

	scope.push :default

	i = 0
	while i < s.length do
		row, col = s[0..i].lines.count, s[0..i].lines.last.length

		return [out, false, "Encountered switch to unknown scope '#{scope.last}' at #{src}:#{row}:#{col}"] if rules[scope.last].nil?

		rule = rules[scope.last].find{ |r| s[i..s.length].index(r.regex) == 0 }
		return [out, false, "Rule not found for '#{s[i]}' in scope '#{scope.last}' at #{src}:#{row}:#{col}"] if rule.nil?
		
		if rule.scope == :< then scope.pop
		else scope.push rule.scope unless rule.scope.nil? end
		
		next_token = Token.new(rule.name, s[i..s.length].match(rule.regex).to_s, src, row, col, scope.join('.'));
		i += next_token.data.length
		out.push next_token
	end
	return out, true
end

puts(tokenize("ab.cde,f..LOLOLOLOL", "source", rules))
