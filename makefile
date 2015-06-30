clients: .PHONY
	ruby -rjson -r./utils/clients -e 'Clients.check(JSON.parse(File.read("clients.json"), symbolize_names: true))'

.PHONY:
