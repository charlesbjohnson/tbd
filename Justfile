default:
	@just --list

fmt:
	@stylua lua/

lint:
	@selene lua/
