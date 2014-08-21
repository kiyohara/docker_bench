module CommandOutputParser
  ### parsed data issue ###
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
      clear_data

      @parsed_data = md[1..-1]
      @parsed_data ||= []

      converted_data = []
      @parsed_data.each do |i|
        converted_data.push(convert(i))
      end
      @parsed_data = converted_data

      @has_parsed = true
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

  def has_parsed?
    @has_parsed ||= false
  end

  def parsed_headers
    []
  end

  ### delta data issue ###
  def calc_delta!(initial_data, prev_data, index)
    @has_delta = true
  end

  def delta_data
    @delta_data ||= []
  end

  def has_delta?
    @has_delta ||= false
  end

  def delta_headers
    []
  end

  ### parsed data & delta data issue ###
  def headers
    res = parsed_headers
    if has_delta?
      res.concat(delta_headers)
    end
    res
  end

  def clear_data
    @parsed_data = []
    @has_parsed = false
    @delta_data = []
    @has_delta = false
  end

  def to_a(with_delta=true)
    res = []

    if has_parsed?
      res = parsed_data
    else
      res.fill('', 0, parsed_headers.size)
    end

    if with_delta && has_delta?
      res.concat(delta_data)
    end

    res
  end

  def from_a(arr)
    clear_data

    data = []
    parsed_headers.each do |i|
      data.push(arr.shift)
    end
    @parsed_data = data
    @has_parsed = true

    arr
  end

  def to_hash(with_delta=true)
    res = {}
    arr_data = to_a

    arr_headers = parsed_headers
    if with_delta && has_delta?
      arr_headers.concat(delta_headers)
    end
    arr_headers.each_with_index do |i, index|
      res[i] = arr_data[index]
    end

    res
  end

  def to_s
    to_a.join(',')
  end

  ### sqlite issue ###
  def sqlite_col_types
    []
  end

  def sqlite_table_defines
    res = []
    parsed_headers.each_with_index do |header, index|
      define=[header, sqlite_col_types[index] || "varchar(256)"]
      res.push(define.join(' '))
    end
    res
  end

  def sqlite_insert_defines
    [].fill('?', 0, parsed_headers.size)
  end
end
