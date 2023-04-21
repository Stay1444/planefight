class_name IPAddress

var Address: String
var Port: int = -1

static func parse(ip: String) -> IPAddress:
	var splitted := ip.split(":", false)
	
	var address := IPAddress.new()
	address.Address = splitted[0]
	if splitted.size() > 1:
		address.Port = int(splitted[1])
	
	return address
