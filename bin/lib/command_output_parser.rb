module CommandOutputParser
  def start_line?(line)
    line =~ /----- #{separator_word} ----->$/
  end

  def end_line?(line)
    line =~ /----- #{separator_word} -----<$/
  end

  def separator_word
    fail NotImplementedError "#{self.class} #{__method__}"
  end

  def parse(line)
    if md = line.match(regexp_parse)
      @parsed_data = md[1..-1]
      @parsed_data ||= []

      converted_data = []
      @parsed_data.each do |i|
        converted_data.push(convert(i))
      end
      @parsed_data = converted_data

      @has_data = true
    end
  end

  def convert(input)
    input
  end

  def regexp_parse
    fail NotImplementedError "#{self.class} #{__method__}"
  end

  def parsed_data
    @parsed_data ||= []
  end

  def to_a
    if has_data?
      parsed_data
    else
      [].fill('', 0, headers.size)
    end
  end

  def parsed_index
    []
  end

  def to_s
    to_a.join(',')
  end

  def has_data?
    @has_data ||= false
  end

  def headers
    []
  end

  def sqlite_col_types
    []
  end

  def sqlite_table_defines
    res = []
    headers.each_with_index do |header, index|
      define=[header, sqlite_col_types[index] || "varchar(256)"]
      res.push(define.join(' '))
    end
    res
  end

  def sqlite_insert_defines
    [].fill('?', 0, headers.size)
  end

  def header
    headers.join(',')
  end
end
