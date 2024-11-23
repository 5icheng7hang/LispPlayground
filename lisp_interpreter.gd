extends Node

class_name Interpreter

@onready var console:Lisp_Console = get_parent()

static func lisp_add(p:Array) -> float:
	var r:float = 0
	for i:float in p:
		r += i
	return r

static func lisp_mul(p:Array) -> float:
	var r:float = 1
	for i:float in p:
		r *= i
	return r

static func lisp_sub(p:Array) -> float:
	if (p.size() == 1):
		return -p.pop_front()
	var r:float = p.pop_front()
	for i:float in p:
		r -= i
	return r
	
static func lisp_div(p:Array) -> float:
	var r:float = p.pop_front()
	for i:float in p:
		r /= i
	return r

static func lisp_gt(p:Array) -> bool:
	for i in p.size()-1:
		if p[i] <= p[i+1]:
			return false
	return true

static func lisp_lt(p:Array) -> bool:
	for i in p.size()-1:
		if p[i] >= p[i+1]:
			return false
	return true

static func lisp_ge(p:Array) -> bool:
	for i in p.size()-1:
		if p[i] < p[i+1]:
			return false
	return true

static func lisp_le(p:Array) -> bool:
	for i in p.size()-1:
		if p[i] > p[i+1]:
			return false
	return true

static func lisp_eq(p:Array) -> bool:
	for i in p.size()-1:
		if p[i] != p[i+1]:
			return false
	return true

static func lisp_neq(p:Array) -> bool:
	for i in p.size()-1:
		if p[i] != p[i+1]:
			return true
	return false

class LispError:
	var ErrorType:String
	var ErrorValue:String
	func _init(type:String, val:String = "") -> void:
		ErrorType = type
		ErrorValue = val
	func _to_string() -> String:
		return "[color=red]" + ErrorType + " : " + ErrorValue + "[/color]"

class EnvironmentContext:
	var bindings:Dictionary = {}
	var outer:EnvironmentContext = null
	
	func search(key:String)->Variant:
		if bindings.has(key):
			return bindings.get(key)
		else:
			print("cannot find sym: " + key + " in: " + str(bindings.keys()))
			if !outer:
				#return "[color=red]Error: Cannot find Symbol: [/color]" + key
				return LispError.new("Eval Error", key)
			return outer.search(key)
		# return bindings.get(key) if bindings.has(key) else outer.search(key)
	
	func addBindings(keys:Array, vals:Array, out:EnvironmentContext = null) -> Variant :
		if (keys.size() != vals.size()):
			return LispError.new("Eval Error", "Arguments doesn't match")
		for i in keys.size():
			bindings[keys[i]] = vals[i]
		outer = out
		return null

static var Standard_env := EnvironmentContext.new()
static var User_env := EnvironmentContext.new()

class Procedure:
	var form_params:Array
	var real_params:Array
	var body:Array
	var localEnv:EnvironmentContext
	
	func _init(in_form_p:Array, in_body:Array, in_env:EnvironmentContext) -> void:
		form_params = in_form_p
		body = in_body
		localEnv = EnvironmentContext.new()
		localEnv.outer = in_env
	
	func invoke_proc(args:Array, env:EnvironmentContext, evalFunc:Callable) -> Variant:
		if localEnv.addBindings(form_params, args, env):
			return localEnv.addBindings(form_params, args, env)
		return evalFunc.call(body, localEnv)
	
	

func tokenize(program: String) -> PackedStringArray:
	return program.replace("(", " ( ").replace(")", " ) ")\
		.replace("\n"," ").replace("\t"," ")\
		.replace("-","- ").split(" ", false)

func Atom(token: String) -> Variant:
	if token.is_valid_float():
		return token.to_float()
	else:
		return str(token)

func parse(tokens: PackedStringArray) -> Variant:
	if tokens.size() == 0:
		return []
	var token: String = tokens[0]
	tokens.remove_at(0)
	if token == "(":
		if tokens.is_empty():
			return LispError.new("Parse Error", "no matching ) found")
		var L: Array = []
		while tokens[0] != ")":
			L.append(parse(tokens))
		tokens.remove_at(0)
		return L
	elif token == ")":
		push_error("unexpected )")
		return []
	else:
		return Atom(token)

static func eval_symbol(exp: Variant, env:EnvironmentContext) -> Variant :
	if exp is Array:
		return exp.map(eval_symbol)
	elif exp is String:
		return env.search(exp)
	else:
		return exp
		
static func eval(exp: Variant, env:EnvironmentContext = User_env) -> Variant:		
	print("eval : " + str(exp))
	print("	" + "in env: " + str(env.bindings))
	if exp is LispError:
		return str(exp)
	if exp is Array:
		if exp.size() == 0:
			return null
		elif exp.size() == 1:
			return eval(exp.front(), env)
		else:
			match exp:
				["define", var name, var body]:
					env.bindings[str(name)] = eval(body, env)
					return null
				["if", var test, var conseq, var alt]:
					return eval(conseq, env) if eval(test, env) else eval(alt, env) 
				["quote", var x]:
					return x
				["lambda", var params, var fnbody]:
					var fp:Array = params if params is Array else [str(params)]
					var fb:Array = fnbody if fnbody is Array else [fnbody]
					var newProc := Procedure.new(fp, fb, env)
					return newProc
				_:
					# treat first element as proc
					exp = exp.map(func(e:Variant)->Variant:return eval(e,env))
					var opt: Variant = eval_symbol(exp.pop_front(), env)
					if opt is Procedure:
						print("invoke proc: " + str(opt))
						return opt.invoke_proc(exp, env, eval)
					elif opt is Callable:
						return opt.call(exp)
					else:
						exp.push_front(opt)
						return exp
	else:
		# Single Element
		print("eval looking for symbol : " + str(exp))
		return eval_symbol(exp, env) if eval_symbol(exp, env) else exp

func RunCode(prog:String) -> String:
	return str(eval(parse(tokenize(prog))))


func _ready() -> void:
	Standard_env.bindings = {
		"+" : lisp_add,
		"*" : lisp_mul,
		"-" : lisp_sub,
		"/" : lisp_div,
		">" : lisp_gt,
		">=" : lisp_ge,
		"<" : lisp_lt,
		"<=" : lisp_le,
		"=" : lisp_eq,
		"!=" : lisp_neq,
		"print" : func (a:Array) -> void : for i:Variant in a :\
			 console.print_onConsole(str(i))
	}
	User_env.outer = Standard_env
