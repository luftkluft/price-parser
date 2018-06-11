puts "********************************************************************************"
puts "*                               ScanPrice                                      *"
puts "*                                 (demo)                                       *"
puts "*                           версия v 3.0.0.0                                   *"
puts "********************************************************************************"
puts "Для прерывания программы нажмите Ctrl+C"

# Подключаем библиотеки
require 'open-uri'
require 'csv'
require_relative 'ruby-progressbar'
require 'nokogiri'

# Глобальные переменные
$pbar = ProgressBar.create( :format         => '%a %b| %i %p%% %t',
                            :progress_mark  => '=',
                            :remainder_mark => '.',
                            :starting_at    => 0)
$url = ''                   # адрес страницы    - позиция 1
$key = ''                   # ключевая фраза    - позиция 2
$intOffset_map = 0          # смещение          - позиция 3
$intBitCapacity_map = 0     # разрядность цены  - позиция 4
$searched_data_global = []
$html = ''

begin
  logFile = File.new("scan_price.log", "a")
  logFile << "Старт программы: "
  logFile << Time.now
  logFile << "\n"
rescue
  puts "Ошибка: #{$!}"
  logFile << "#{$!}   "
  logFile << Time.now
  logFile << "\n"
end
    
begin
  line_count = 0
  File.open("scan_price.map").each{ |line| line_count += 1 }
  $pbar.total = line_count
rescue
  puts "Не удалось открыть map-файл :("
  puts "Нет возможности обработать запрос..."
  logFile << "Не удалось открыть map-файл :("
end

def key_position(strKey, strJson, intStart)

  l = strJson.length      
  l_key = strKey.length    
  count_char = intStart
  count_char_key = l_key

  while count_char_key >= 2 && count_char <= l - 1
    char = strJson[count_char]
    count_char = count_char + 1
    if char == strKey[l_key - count_char_key]
      count_char_key = count_char_key - 1
    else
      count_char_key = l_key
    end
  end

  if count_char <= l - 1
    return count_char + 2 - l_key
  else
    return -1
  end

end

def key_offset_value (intOffset, intBitCapacity, strJson)

  l = strJson.length

  if (intOffset) <= -1
    return "###<"
  end

  if (intOffset + intBitCapacity) >= l + 1
    return "###>"
  end

  value = strJson[intOffset..(intOffset + intBitCapacity-1)]
  return value 

end

count_row = 0
count_column = 0
count_line = 0
count_block = 0

map = File.new("scan_price.map", "r+")

while (ml = map.gets)
  if ml[0] == '/'
  end
  if ml[0] == '<'
    count_column = count_column + 1
    $searched_data_global << ml.to_s.delete('<').chomp
  end
  if ml[0] == '>'
    count_row = count_row + 1
    $searched_data_global << ml.to_s.delete('>').chomp
  end
  if ml[0] == '*'
    $searched_data_global << ml.to_s.delete('*').chomp
  end
  if ml[0] == '#'
    count_block = count_block + 1
    if count_block == 1
      $url = ml.to_s.delete('#')
    end
    if count_block == 2
      $key = ml.to_s.delete('#')
    end
    if count_block == 3
      $intOffset_map = ml.to_s.delete('#')
    end
    if count_block == 4
      count_block = 0
      $intBitCapacity_map = ml.to_s.delete('#')
      begin
        doc = Nokogiri::HTML(open($url)) 
      rescue
        puts "Ссылка: #{$url}"
        puts "Error: #{$!}"
        logFile << "\n"
        logFile << "#{$!}"
        logFile << "\n"
        logFile << "Ссылка: #{$url}"
        logFile << "=начало массива="
        logFile << "\n"
        logFile << "Error url: #{$searched_data_global}"
        logFile << "\n"
        logFile << "=конец массива="
        logFile << "\n"
        logFile << Time.now
        logFile << "\n"
        $searched_data_global << "error url"
      end
      sleep (1)
      intKey_position = key_position($key, doc.to_s, 0)
      totalOffset = $intOffset_map.to_i + intKey_position
      l_key_value = key_offset_value(totalOffset, $intBitCapacity_map.to_i, doc.to_s).length
      if l_key_value >= 1
        $searched_data_global << key_offset_value(totalOffset, $intBitCapacity_map.to_i, doc.to_s).to_s
      else
        puts "Error cell"
      end
    end
  end
  count_line = count_line + 1
  $pbar.increment
end

map.close

logFile << "$searched_data_global = #{$searched_data_global.inspect}"
logFile << "\n"
puts "********************************************************************************"
# Образец сформированного массива
# SearchArray = ['Produkt name', 'Сайт 1','Сайт 2', 'Сайт 3',
#                'Produkt 1', 'Price 1.1', 'Price 2.1', 'Price 3.1',
#                'Produkt 2', 'Price 1.2', 'Price 2.2', 'Price 3.2',
#                'Produkt 3', 'Price 1.3', 'Price 2.3', 'Price 3.3']
TempArray = []

def csv_save(searched_data_global, count_col, temp_array)

  searched_data = searched_data_global
  time = Time.now.to_s
  time = time.delete('-')
  time = time.delete(':')
  time = time.delete('+')
  l = searched_data.length

  CSV.open('price_data/'+time+'.csv', 'w') do |writer|

    count_data = 0

    while count_data <= l - 1
    count_fill = -1
      while count_fill <= count_col - 2
        count_fill = count_fill + 1
        TempArray << searched_data[count_data + count_fill].to_s
          if (count_fill == count_col - 1)
          writer << TempArray
          TempArray.clear
          end
      end
      count_data = count_data + count_col
    end

  end

end

begin
  csv_save($searched_data_global, count_column, TempArray)
rescue
  puts "Ошибка сохранения результатов сканирования: #{$!}"
  logFile << "#{$!}   "
  logFile << Time.now
  logFile << "\n"
end

$pbar.finish

logFile << "\n"
logFile << "Стоп программы: "
logFile << Time.now
logFile << "\n"
logFile.close

puts Time.now
puts "Сканирование завершено."
puts "Результаты сканирования в файле *csv в папке price_data"
puts "Имя файла состоит из текущих даты и времени."
puts "Подробности сканирования смотрите в лог-файле scan_price.log."
puts "Для выхода из программы нажмите \"ввод\"..."
STDIN.getc
