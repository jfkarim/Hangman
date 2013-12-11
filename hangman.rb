class Hangman
  attr_accessor :guesser, :confirmer, :secret_word_length, :wrong_guess_count, :board, :pick, :pick_coordinates

  def game
    start_game
    play
    play_again
  end

  def start_game
    puts "How many human players would you like? (0, 1, 2)"
    players = gets.chomp.to_i

    if players == 1
      one_human_player
    elsif players == 2
      two_human_players
    else
      computers_only
    end

    game_initials
  end

  def one_human_player
    puts "Would you like to start guessing or confirming?"
    ans = gets.chomp.downcase[0]
    if ans == 'g'
      chose_guesser
    else
      chose_confirmer
    end
  end

  def two_human_players
    self.guesser = HumanPlayer.new
    guesser.guesser_initialize
    self.confirmer = HumanPlayer.new
    confirmer.confirmer_initialize
  end

  def computers_only
    self.guesser = ComputerPlayer.new
    guesser.guesser_initialize
    self.confirmer = ComputerPlayer.new
    confirmer.confirmer_initialize
  end

  def game_initials
    self.secret_word_length = confirmer.secret_word_length
    self.board = Board.new(secret_word_length)
    self.wrong_guess_count = 0
    puts game_board
  end

  def chose_guesser
    self.guesser = HumanPlayer.new
    guesser.guesser_initialize
    self.confirmer = ComputerPlayer.new
    confirmer.confirmer_initialize
  end

  def chose_confirmer
    self.guesser = ComputerPlayer.new
    guesser.guesser_initialize
    self.confirmer = HumanPlayer.new
    confirmer.confirmer_initialize
  end

  def play
    loop do
      round

      if win?
        win
        break

      elsif wrong_guess_count > 5
        lose
        break

      end
    end
  end

  def win
    puts "Congratulations, you didn't die!"
  end

  def lose
    puts "You've been hung out to dry!"
  end

  def play_again
    puts "Play again? (y/n)"
    ans = gets.chomp.downcase[0]
    if ans == "y"
      game
    end
  end

  def game_board
    board.secret_board
  end

  def round
    show_used_letters
    show_wrong_guesses

    guessing
    update_guessed_letters
    if_wrong_guess

    show_updated_board
  end

  def guessing
    loop do
      self.pick = guesser.guess(game_board, secret_word_length)
      return pick if pick.length > 1
      self.pick_coordinates = confirmer.confirm_letter(pick)
      break if valid_guess?
    end
  end

  def wrong_guess?(coordinates)
    if pick.length > 1
      if confirmer.class == ComputerPlayer
        pick != confirmer.secret_word ? true : false
      else
        !confirmer.confirm_word?(pick)
      end
    else
      coordinates.empty?
    end
  end

  def if_wrong_guess
    self.wrong_guess_count += 1 if wrong_guess?(pick_coordinates)
  end

  def update_guessed_letters
    guesser.update_guessed_letters(pick)
  end

  def show_updated_board
    board.populator(pick, pick_coordinates) unless pick.length > 1
    puts game_board
  end

  def show_wrong_guesses
    puts "You have guessed wrong #{wrong_guess_count} times."
  end

  def show_used_letters
    puts "Letters and words used: #{guesser.guessed_letters.join(' ')}"
  end

  def valid_guess?
    !guesser.guessed_letters.include?(pick)
  end

  def win?
    if pick.length > 1 && confirmer.class == ComputerPlayer
      pick == confirmer.secret_word ? true : false
    elsif pick.length > 1
      confirmer.confirm_word?(pick)
    else
      !game_board.include?('_')
    end
  end
end



class HumanPlayer
  attr_accessor :secret_word_length, :name, :guessed_letters

  def initialize
    puts "What is your name?"
    @name = gets.chomp.capitalize
  end

  #Confirmer_methods

  def confirmer_initialize
    puts "#{name}, keep your REAL word in mind. Do not type it. Type the length of the word you chose:"
    self.secret_word_length = gets.chomp.to_i
  end

  def confirm_letter(letter)
    puts "Letter guessed: #{letter}"
    puts "#{name}, is this letter in your word? (y/n)"
    if gets.chomp.downcase[0] == 'y'
      puts "#{name}, type position(s) of letter separated by commas:"
      ans = gets.chomp.split(',').map { |num| num.to_i-1 } # Maybe subtract one?
    else
      []
    end
  end

  def confirm_word?(word)
    ans = ''
    loop do
      puts "#{name}, is #{word} your word? (y/n)"
      ans = gets.chomp.downcase[0]
      break if 'yn'.include?(ans)
      puts "Invalid, use (y/n)."
    end
    ans == 'y' ? true : false
  end

  #Guesser methods

  def guesser_initialize
    puts "#{name}, begin guessing letters, you have 6 tries before your man hangs."
    self.guessed_letters = []
  end

  def update_guessed_letters(pick)
    guessed_letters << pick
  end

  def guess_letter
    pick = ''
    loop do
      puts "#{name}, guess a letter:"
      pick = gets.chomp.downcase[0]
      break if ("a".."z").to_a.include?(pick)
    end
    pick
  end

  def guess_word
    puts "#{name}, guess a word of the same length:"
    pick = gets.chomp.downcase
  end

  def guess(game_board, secret_word_length)
    ans = 'l'
    loop do
      puts "#{name}, would you like to guess a word or letter?"
      ans = gets.chomp.downcase[0]
      break if 'wl'.include?(ans)
    end
    return guess_letter if ans == 'l'
    return guess_word if ans == 'w'
  end

end

##############################

# class Guesser
#
# end
#
# class Confirmer
#   def initialize
#     @
#   end
# end
#
# class Human
#   def initialize
#     @name
#   end
# end
#
# end
#
# class Computer
#
# end

##############################

class ComputerPlayer
  attr_accessor :secret_word, :alphabet, :guessed_letters, :dictionary

  def initialize
    @dictionary = File.readlines("dictionary.txt").map(&:chomp)
    @alphabet = ("a".."z").to_a
  end

  #Guesser methods

  def string_to_regex(string)
    new_regex = string.gsub("_", "[a-z]")
    Regexp.new(new_regex)
  end

  def guesser_initialize
    self.guessed_letters = []
  end

  def get_possible_words(string, secret_word_length)
    possible_words = dictionary.grep(string_to_regex(string))
    possible_words.select do |word|
      !string.include?(word) && word.length == secret_word_length
    end
  end

  def smart_guess(string, secret_word_length)
    get_possible_words(string, secret_word_length).sample
  end

  def update_guessed_letters(pick)
    guessed_letters << pick
  end

  def guess(string, secret_word_length)
    smart_word = []
    loop do
      smart_word = (smart_guess(string, secret_word_length).split('') - guessed_letters)
      break if smart_word != []
    end
    smart_word.sample
  end

  #Confirmer methods

  def confirmer_initialize
    self.secret_word = dictionary.sample
    puts "Computer has chosen a word of length #{secret_word.length}."
  end

  def secret_word_length
    secret_word.length
  end

  def confirm_letter(input_letter)
    positions = []
    secret_word.split('').each_with_index do |letter, index|
      if letter == input_letter
        positions << index
      end
    end
    positions
  end

end

class Board
  attr_accessor :secret_board

  def initialize(secret_word_length)
    @secret_board = ''
    secret_word_length.times do
      @secret_board << '_'
    end
  end

  def populator(letter, positions)
    positions.each do |position|
      secret_board[position] = letter
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  hangman = Hangman.new
  hangman.game
end