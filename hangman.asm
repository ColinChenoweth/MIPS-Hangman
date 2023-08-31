	.data

intro_msg:	.asciiz	"Guessers Look Away"
word_prompt:	.asciiz	"Enter word or phrase to be guessed (in all lowercase):"
guess_prompt:	.asciiz "Enter a letter or the full word/phrase to guess (in lowercase):"
already_guessed_msg:	.asciiz	"Already guessed this letter, try again."
yes_in_word_msg:	.asciiz	"Correct, that letter is in the word."
not_in_word_msg:	.asciiz	"Sorry, incorrect guess."
lives_msg:	.asciiz "Lives remaining:  "
game_lost_msg:	.asciiz	"You Lost :("
game_won_msg:	.asciiz "You Won!! :)"
word_msg:	.asciiz "The word was:  "
unguessed_letters:	.asciiz "abcdefghijklmnopqrstuvwxyz"
guessed_word: .space 256
word:	.space	256
word_length: .word 0
current_letter: .space 256
letter_valid: .word 0		# 0 = not guessed, not in word, 1 = not guessed, in word, 2 = already guessed
lives: .word 6

	.text
# Gets word to be guessed and adds a bunch of new lines so the guesser does not see the word. Then stars the first guess.
main:
	li $v0, 4
 	la $a0, intro_msg
	syscall
	
	jal new_line
	
 	li $v0, 4
	la $a0, word_prompt
	syscall
	
	li $v0, 8
	la $a0, word
	li $a1, 256
	syscall
	
	li $t0, 0
	la $a0, word
	jal get_word_length
	
	jal new_line
	jal new_line
	jal new_line
	jal new_line
	jal new_line
	jal new_line
	jal new_line
	jal new_line
	jal new_line
	jal new_line
	jal new_line
	jal new_line
	
	j guess
	
# The main guess method. Prints the game_board, gets a guess, determines if guess is a word or a letter and checks guess respectively.
guess:
	jal game_board
	
	# display guess prompt
 	li $v0, 4
	la $a0, guess_prompt
	syscall

	# take input
	li $v0, 8
	la $a0, current_letter
	li $a1, 256
	syscall

	li $t0, 0
	jal check_guess_length

	beq, $t0, 2, check_guess_letter
	
	li $t0, 0
	li $t1, 256
	j check_guess_phrase
	
# Determines length of guess, stores it in $t0.
check_guess_length:
	lb $t1, current_letter($t0)
	beqz $t1, return
	addi $t0, $t0, 1
	j check_guess_length
	
# Checks if guess (which is phrase) is equal to the word/phrase to be guessed. If same game is over if not guess is incorrect
check_guess_phrase:
	beq $t0, $t1, game_over
	lb $t2, word($t0)
	lb $t3, current_letter($t0)
	bne $t2, $t3, wrong_guess
	addi $t0, $t0, 1
	j check_guess_phrase
	
# Checks if guess (which is a letter) has already been guessed or if it is in the word or not.
check_guess_letter:
	li $t0, 0
	sw $t0, letter_valid
	
	li $t0, 0
	li $t1, 26
	jal check_already_guessed
	
	li $t0, 0
	lw $t1, word_length
	jal check_in_word
	
	li $t2, 0
	lw $t3, letter_valid
	beq $t2, $t3, wrong_guess
	
	j yes_in_word_outputs

# The main game board method that prints lives remaining, the current guessed version of the word/phrase, and 
# ends the game if either it the guesed version is correct or there are no more lives.
game_board:
	la $s0, ($ra)
	
	li $v0, 1
	lw $a0, lives
	syscall
	
	jal new_line
	
	li $t0, 0
	lw $t1, word_length
	jal display_guessed_word
	
	jal new_line
	
	lw $t0, lives
	beqz $t0, game_over
	
	li $t0, 0
	lw $t1, word_length
	la $a0, game_over
	jal check_equal
	
	jr $s0
	
# The main game over method, checks if there are still lives left to determine if game is lost or won.
game_over:
	lw $t0, lives
	beqz $t0, game_lost
	j game_won
	
# Prints game won and the original word/phrase. Also exits the program
game_won:
 	li $v0, 4
	la $a0, game_won_msg
	syscall

	jal new_line

	jal display_word

	# exit program
	li $v0, 10
	syscall

# Prints game lost and the orginal word/phrase. Also exits the program
game_lost:
 	li $v0, 4
	la $a0, game_lost_msg
	syscall
	
	jal new_line

	jal display_word

	# exit program
	li $v0, 10
	syscall




# Helper methods


# Helper method that checks if the guessed letter is in the unguessed_letter string.
# If it isn't in that string (meaning it has already been guessed) then go back to guess method no penalty, otherwise continue checking letter.
check_already_guessed:
	beq $t0, $t1, already_guessed
	lb $t2, unguessed_letters($t0)
	lb $t3, current_letter
	beq $t2, $t3, unguessed
	addi $t0, $t0, 1
	j check_already_guessed

# Helper method that removes the guessed letter from the unguessed string and returns to checking letter
unguessed:
	sb $zero, unguessed_letters($t0)
	jr $ra
	
# Helper method that prints letter has already been guessed and goes to a new guess.
already_guessed:
	li $t0, 2
	sw $t0, letter_valid
	
	li $v0, 4
	la $a0, already_guessed_msg
	syscall
	
	jal new_line
	jal new_line
	
	j guess

# Helper method that checks if the letter is in the word/phrase.
# If so it fills it in in the guessed version of word/phrase and marks letter as valid.
check_in_word:
	beq $t0, $t1, return
	lb $t2, word($t0)
	lb $t3, current_letter
	beq $t2, $t3, fill_in_letter
	addi $t0, $t0, 1
	j check_in_word

# Helper method that fills in the letter into the current guessed version of the word/phrase.
fill_in_letter:
	li $t3, 1
	sw $t3, letter_valid
	lb $t4, current_letter
	sb $t4, guessed_word($t0)
	
	addi $t0, $t0, 1
	j check_in_word
	
# Helper method that prints they guessed correctly and starts a new guess.
yes_in_word_outputs:
	li $v0, 4
	la $a0, yes_in_word_msg
	syscall
	
	jal new_line
	jal new_line
	
	j guess
	
# Helper method that removes a life, prints incorrect guess, and starts a new guess.
wrong_guess:
	lw $t0, lives
	subi $t0, $t0, 1
	sw $t0, lives

	li $v0, 4
	la $a0, not_in_word_msg
	syscall
	
	jal new_line
	jal new_line
	
	j guess

# Helper method that prints the guessed versin of the word.
display_guessed_word:
	beq $t0, $t1, return
	lb $t2, guessed_word($t0)
	beqz $t2, display_blank

	li $v0, 11
	lb $a0, guessed_word($t0)
	syscall
	addi $t0, $t0, 1
	j display_guessed_word
	
# Helper method that prints an underscore.
display_blank:
	li $v0, 11
	li $a0, '_'
	syscall
	addi $t0, $t0, 1
	j display_guessed_word
	
# Helper method that checks if the guessed version of the word/phrase is the same as the real word/phrase
check_equal:
	beq $t0, $t1, game_over
	lb $t2, word($t0)
	lb $t3, guessed_word($t0)
	bne $t2, $t3, return
	addi $t0, $t0, 1
	j check_equal

# Helper method that stores the word length of the original word/phrase in word_length.
get_word_length:
	lb $t1, word($t0)
	beqz $t1, return
	li $t2, ' '
	beq $t1, $t2, add_space
	sw $t0, word_length
	addi $t0, $t0, 1
	j get_word_length
	
# Helper method that aadds spaces into the guessed version of the word/phrase so they do not need to be guessed.
add_space:
	sb $t2, guessed_word($t0)
	sw $t0, word_length
	addi $t0, $t0, 1
	j get_word_length
	
# Helper method that prints a new line.
new_line:
	li $a0, 0xA
	li $v0, 11
	syscall
	
	jr $ra
	
# Helper method that prints the original word/phrase.
display_word:
	li $v0, 4
	la $a0, word_msg
	syscall
	li $v0, 4
	la $a0, word
	syscall
	
	jr $ra
	
# Helper method that returns to address $ra.
return:
	jr $ra
