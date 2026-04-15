# License : GPLv2.0
# copyright (c) 2026  Dave Bailey
# Author: Dave Bailey (dbisu, @daveisu)
#
#  TODO: ADD support for the following:
# Add jitter
# Add LED functionality
import re
import time
import random
import digitalio
from digitalio import DigitalInOut, Pull
from adafruit_debouncer import Debouncer
import board
from board import *
import asyncio
import usb_hid
from adafruit_hid.keyboard import Keyboard
from adafruit_hid.consumer_control import ConsumerControl
from adafruit_hid.consumer_control_code import ConsumerControlCode
from pins import *

# comment out these lines for non_US keyboards
from adafruit_hid.keyboard_layout_us import KeyboardLayoutUS as KeyboardLayout
from adafruit_hid.keycode import Keycode

# uncomment these lines for non_US keyboards
# replace LANG with appropriate language
#from keyboard_layout_win_LANG import KeyboardLayout as KeyboardLayout
#from keycode_win_LANG import Keycode

def _capsOn():
    return kbd.led_on(Keyboard.LED_CAPS_LOCK)

def _numOn():
    return kbd.led_on(Keyboard.LED_NUM_LOCK)

def _scrollOn():
    return kbd.led_on(Keyboard.LED_SCROLL_LOCK)

def pressLock(key):
    kbd.press(key)
    kbd.release(key)

def SaveKeyboardLedState():
    variables["$_INITIAL_SCROLLLOCK"] = _scrollOn()
    variables["$_INITIAL_NUMLOCK"] = _numOn()
    variables   ["$_INITIAL_CAPSLOCK"] = _capsOn()


def RestoreKeyboardLedState():
    if(variables["$_INITIAL_CAPSLOCK"] != _capsOn()):
        pressLock(Keycode.CAPS_LOCK)
    if(variables["$_INITIAL_NUMLOCK"] != _numOn()):
        pressLock(Keycode.NUM_LOCK)
    if(variables["$_INITIAL_SCROLLLOCK"] != _scrollOn()):
        pressLock(Keycode.SCROLL_LOCK)

duckyKeys = {
    'WINDOWS': Keycode.GUI, 'RWINDOWS': Keycode.RIGHT_GUI, 'GUI': Keycode.GUI, 'RGUI': Keycode.RIGHT_GUI, 'COMMAND': Keycode.GUI, 'RCOMMAND': Keycode.RIGHT_GUI,
    'APP': Keycode.APPLICATION, 'MENU': Keycode.APPLICATION, 'SHIFT': Keycode.SHIFT, 'RSHIFT': Keycode.RIGHT_SHIFT,
    'ALT': Keycode.ALT, 'RALT': Keycode.RIGHT_ALT, 'OPTION': Keycode.ALT, 'ROPTION': Keycode.RIGHT_ALT, 'CONTROL': Keycode.CONTROL, 'CTRL': Keycode.CONTROL, 'RCTRL': Keycode.RIGHT_CONTROL,
    'DOWNARROW': Keycode.DOWN_ARROW, 'DOWN': Keycode.DOWN_ARROW, 'LEFTARROW': Keycode.LEFT_ARROW,
    'LEFT': Keycode.LEFT_ARROW, 'RIGHTARROW': Keycode.RIGHT_ARROW, 'RIGHT': Keycode.RIGHT_ARROW,
    'UPARROW': Keycode.UP_ARROW, 'UP': Keycode.UP_ARROW, 'BREAK': Keycode.PAUSE,
    'PAUSE': Keycode.PAUSE, 'CAPSLOCK': Keycode.CAPS_LOCK, 'DELETE': Keycode.DELETE,
    'END': Keycode.END, 'ESC': Keycode.ESCAPE, 'ESCAPE': Keycode.ESCAPE, 'HOME': Keycode.HOME,
    'INSERT': Keycode.INSERT, 'NUMLOCK': Keycode.KEYPAD_NUMLOCK, 'PAGEUP': Keycode.PAGE_UP,
    'PAGEDOWN': Keycode.PAGE_DOWN, 'PRINTSCREEN': Keycode.PRINT_SCREEN, 'ENTER': Keycode.ENTER,
    'SCROLLLOCK': Keycode.SCROLL_LOCK, 'SPACE': Keycode.SPACE, 'TAB': Keycode.TAB,
    'BACKSPACE': Keycode.BACKSPACE,
    'A': Keycode.A, 'B': Keycode.B, 'C': Keycode.C, 'D': Keycode.D, 'E': Keycode.E,
    'F': Keycode.F, 'G': Keycode.G, 'H': Keycode.H, 'I': Keycode.I, 'J': Keycode.J,
    'K': Keycode.K, 'L': Keycode.L, 'M': Keycode.M, 'N': Keycode.N, 'O': Keycode.O,
    'P': Keycode.P, 'Q': Keycode.Q, 'R': Keycode.R, 'S': Keycode.S, 'T': Keycode.T,
    'U': Keycode.U, 'V': Keycode.V, 'W': Keycode.W, 'X': Keycode.X, 'Y': Keycode.Y,
    'Z': Keycode.Z, 'F1': Keycode.F1, 'F2': Keycode.F2, 'F3': Keycode.F3,
    'F4': Keycode.F4, 'F5': Keycode.F5, 'F6': Keycode.F6, 'F7': Keycode.F7,
    'F8': Keycode.F8, 'F9': Keycode.F9, 'F10': Keycode.F10, 'F11': Keycode.F11,
    'F12': Keycode.F12, 'F13': Keycode.F13, 'F14': Keycode.F14, 'F15': Keycode.F15,
    'F16': Keycode.F16, 'F17': Keycode.F17, 'F18': Keycode.F18, 'F19': Keycode.F19,
    'F20': Keycode.F20, 'F21': Keycode.F21, 'F22': Keycode.F22, 'F23': Keycode.F23,
    'F24': Keycode.F24
}
duckyConsumerKeys = {
    'MK_VOLUP': ConsumerControlCode.VOLUME_INCREMENT, 'MK_VOLDOWN': ConsumerControlCode.VOLUME_DECREMENT, 'MK_MUTE': ConsumerControlCode.MUTE,
    'MK_NEXT': ConsumerControlCode.SCAN_NEXT_TRACK, 'MK_PREV': ConsumerControlCode.SCAN_PREVIOUS_TRACK,
    'MK_PP': ConsumerControlCode.PLAY_PAUSE, 'MK_STOP': ConsumerControlCode.STOP
}

variables = {"$_RANDOM_MIN": 0, "$_RANDOM_MAX": 65535,"$_EXFIL_MODE_ENABLED": False,"$_EXFIL_LEDS_ENABLED": False,"$_INITIAL_SCROLLLOCK": False, "$_INITIAL_NUMLOCK": False, "$_INITIAL_CAPSLOCK": False}
internalVariables = {"$_CAPSLOCK_ON": _capsOn, "$_NUMLOCK_ON": _numOn, "$_SCROLLLOCK_ON": _scrollOn}
defines = {}
functions = {}

letters = "abcdefghijklmnopqrstuvwxyz"
numbers = "0123456789"
specialChars = "!@#$%^&*()"

class IF:
    def __init__(self, condition, codeIter):
        self.condition = condition
        self.codeIter = list(codeIter)
        self.lastIfResult = None
    
    def _exitIf(self):
        _depth = 0
        for line in self.codeIter:
            line = self.codeIter.pop(0)
            line = line.strip()
            if line.upper().startswith("END_IF"):
                _depth -= 1
            elif line.upper().startswith("IF"):
                _depth += 1
            if _depth < 0:
                print("No else, exiting" + str(list(self.codeIter)))
                break
        return(self.codeIter)

    def runIf(self):
        if isinstance(self.condition, str):
            self.lastIfResult = evaluateExpression(self.condition)
        elif isinstance(self.condition, bool):
            self.lastIfResult = self.condition
        else:
            raise ValueError("Invalid condition type")

        # print(f"condition {self.condition} result is {self.lastIfResult} since \"$VAR\" is {variables["$VAR"]}, code is {self.codeIter}")
        depth = 0
        for line in self.codeIter:
            line = self.codeIter.pop(0)
            line = line.strip()
            if line == "":
                continue
            # print(line)

            if line.startswith("IF"):
                depth += 1
            elif line.startswith("END_IF"):
                if depth == 0:
                    return(self.codeIter, -1)
                depth -=1

            elif line.startswith("ELSE") and depth == 0:
                # print(f"ELSE LINE {line}, lastIfResult: {self.lastIfResult}")
                if self.lastIfResult is False:
                    line = line[4:].strip()  # Remove 'ELSE' and strip whitespace
                    if line.startswith("IF"):
                        nestedCondition = _getIfCondition(line)
                        # print(f"nested IF {nestedCondition}")
                        self.codeIter, self.lastIfResult = IF(nestedCondition, self.codeIter).runIf()
                        if self.lastIfResult == -1 or self.lastIfResult == True:
                            # print(f"self.lastIfResult {self.lastIfResult}")
                            return(self.codeIter, True)
                    else:
                        return IF(True, self.codeIter).runIf()                        #< Regular ELSE block
                else:
                    self._exitIf()
                    break

            # Process regular lines
            elif self.lastIfResult:
                # print(f"running line {line}")
                self.codeIter = list(parseLine(line, self.codeIter))
        # print("end of if")
        return(self.codeIter, self.lastIfResult)

def _getIfCondition(line):
    return str(line)[2:-4].strip()

def _isCodeBlock(line):
    line = line.upper().strip()
    if line.startswith("IF") or line.startswith("WHILE"):
        return True
    return False

def _getCodeBlock(linesIter):
    """Returns the code block starting at the given line."""
    code = []
    depth = 1
    for line in linesIter:
        line = line.strip()
        if line.upper().startswith("END_"):
            depth -= 1
        elif _isCodeBlock(line):
            depth += 1
        if depth <= 0:
            break
        code.append(line)
    return code

def replaceBooleans(text):                             #< fix capitalization mistakes in true and false (for evaluating with booleans)
    # Replace any letter-by-letter match for "true" with the proper "True"
    text = re.sub(r'[Tt][Rr][Uu][Ee]', 'True', text)
    # Replace any letter-by-letter match for "false" with the proper "False"
    text = re.sub(r'[Ff][Aa][Ll][Ss][Ee]', 'False', text)
    return text

def is_safe_expression(expression):
    if re.search(r'__|import|exec|eval|open|os|sys|subprocess|socket|shlex|inspect|compile|globals|locals|getattr|setattr|delattr|class|lambda', expression, re.IGNORECASE):
        return False
    return re.match(r'^[0-9A-Za-z\s\.\+\-\*\/\%\(\)<>=!&\|\^,\'\"]+$', expression) is not None


def evaluateExpression(expression):
    """Evaluates an expression with variables and returns the result."""
    expression = replaceVariables(expression)
    expression = replaceBooleans(expression)       #< Cant use re due its limitation in circutpython
    print(expression)

    expression = expression.replace("^", "**")     #< Replace ^ with ** for exponentiation
    expression = expression.replace("&&", "and")
    expression = expression.replace("||", "or")

    expression = expression.replace("TRUE", "True")
    expression = expression.replace("FALSE", "False")

    if not is_safe_expression(expression):
        raise ValueError("Unsafe expression")
    return eval(expression, {'__builtins__': {}}, {})

def deepcopy(List):
    return(List[:])

def convertLine(line):
    commands = []
    # print(line)
    # loop on each key - the filter removes empty values
    for key in filter(None, line.split(" ")):
        key = key.upper()
        # find the keycode for the command in the list
        command_keycode = duckyKeys.get(key, None)
        command_consumer_keycode = duckyConsumerKeys.get(key, None)
        if command_keycode is not None:
            # if it exists in the list, use it
            commands.append(command_keycode)
        elif command_consumer_keycode is not None:
            # if it exists in the list, use it
            commands.append(1000+command_consumer_keycode)
        elif hasattr(Keycode, key):
            # if it's in the Keycode module, use it (allows any valid keycode)
            commands.append(getattr(Keycode, key))
        else:
            # if it's not a known key name, show the error for diagnosis
            print(f"Unknown key: <{key}>")
    # print(commands)
    return commands

def runScriptLine(line):
    keys = convertLine(line)
    for k in keys:
        if k > 1000:
            consumerControl.press(int(k-1000))
        else:
            kbd.press(k)
    for k in reversed(keys):
        if k > 1000:
            consumerControl.release()
        else:
            kbd.release(k)

def sendString(line):
    layout.write(line)

def replaceVariables(line):
    for var in variables:
        line = line.replace(var, str(variables[var]))
    for var in internalVariables:
        line = line.replace(var, str(internalVariables[var]()))
    return line

def replaceDefines(line):
    for define, value in defines.items():
        line = line.replace(define, value)
    return line

async def _handle_inject_mod(line, script_lines):
    return script_lines

async def _handle_rem_block(line, script_lines):
    while not line.startswith("END_REM"):
        line = next(script_lines).strip()
    return script_lines

async def _handle_rem(line, script_lines):
    return script_lines

async def _handle_hold(line, script_lines):
    key = line[5:].strip().upper()
    commandKeycode = duckyKeys.get(key, None)
    if commandKeycode:
        kbd.press(commandKeycode)
    else:
        print(f"Unknown key to HOLD: <{key}>")
    return script_lines

async def _handle_release(line, script_lines):
    key = line[8:].strip().upper()
    commandKeycode = duckyKeys.get(key, None)
    if commandKeycode:
        kbd.release(commandKeycode)
    else:
        print(f"Unknown key to RELEASE: <{key}>")
    return script_lines

async def _handle_delay(line, script_lines):
    line = replaceVariables(line)
    await asyncio.sleep(float(line[6:]) / 1000)
    return script_lines

async def _handle_stringln(line, script_lines):
    if line == "STRINGLN":
        line = next(script_lines).strip()
        line = replaceVariables(line)
        while not line.startswith("END_STRINGLN"):
            sendString(line)
            kbd.press(Keycode.ENTER)
            kbd.release(Keycode.ENTER)
            line = next(script_lines).strip()
            line = replaceVariables(line)
            line = replaceDefines(line)
    else:
        sendString(replaceVariables(line[9:]))
        kbd.press(Keycode.ENTER)
        kbd.release(Keycode.ENTER)
    return script_lines

async def _handle_string(line, script_lines):
    if line == "STRING":
        line = next(script_lines).strip()
        line = replaceVariables(line)
        while not line.startswith("END_STRING"):
            sendString(line)
            line = next(script_lines).strip()
            line = replaceVariables(line)
            line = replaceDefines(line)
    else:
        sendString(replaceVariables(line[7:]))
    return script_lines

async def _handle_print(line, script_lines):
    line = replaceVariables(line[6:])
    print("[SCRIPT]: " + line)
    return script_lines

async def _handle_import(line, script_lines):
    runScript(line[7:])
    return script_lines

async def _handle_default_delay(line, script_lines):
    global defaultDelay
    if line.startswith("DEFAULT_DELAY"):
        defaultDelay = int(line[14:]) * 10
    else:
        defaultDelay = int(line[13:]) * 10
    return script_lines

async def _handle_led(line, script_lines):
    if led.value == True:
        led.value = False
    else:
        led.value = True
    return script_lines

async def _handle_led_off(line, script_lines):
    led.value = False
    return script_lines

async def _handle_led_on(line, script_lines):
    led.value = True
    return script_lines

async def _handle_wait_for_button_press(line, script_lines):
    button_pressed = False
    while not button_pressed:
        button1.update()

        button1Pushed = button1.fell
        button1Released = button1.rose
        button1Held = not button1.value

        if button1Pushed:
            print("Button 1 pushed")
            button_pressed = True
    return script_lines

async def _handle_var(line, script_lines):
    match = re.match(r"VAR\s+\$(\w+)\s*=\s*(.+)", line)
    if match:
        varName = f"${match.group(1)}"
        value = evaluateExpression(match.group(2))
        variables[varName] = value
    else:
        raise SyntaxError(f"Invalid variable declaration: {line}")
    return script_lines

async def _handle_variable_update(line, script_lines):
    match = re.match(r"\$(\w+)\s*=\s*(.+)", line)
    if match:
        varName = f"${match.group(1)}"
        expression = match.group(2)
        value = evaluateExpression(expression)
        variables[varName] = value
    else:
        raise SyntaxError(f"Invalid variable update, declare variable first: {line}")
    return script_lines

async def _handle_define(line, script_lines):
    defineLocation = line.find(" ")
    valueLocation = line.find(" ", defineLocation + 1)
    defineName = line[defineLocation+1:valueLocation]
    defineValue = line[valueLocation+1:]
    defines[defineName] = defineValue
    return script_lines

async def _handle_function(line, script_lines):
    func_name = line.split()[1]
    functions[func_name] = []
    line = next(script_lines).strip()
    while line != "END_FUNCTION":
        functions[func_name].append(line)
        line = next(script_lines).strip()
    return script_lines

async def _handle_while(line, script_lines):
    condition = line[5:].strip()
    loopCode = list(_getCodeBlock(script_lines))
    while evaluateExpression(condition) == True:
        currentIterCode = deepcopy(loopCode)
        while currentIterCode:
            loopLine = currentIterCode.pop(0)
            currentIterCode = list(parseLine(loopLine, iter(currentIterCode)))
    return script_lines

async def _handle_if(line, script_lines):
    script_lines, ret = IF(_getIfCondition(line), script_lines).runIf()
    print(f"IF returned {ret} code")
    return script_lines

async def _handle_end_if(line, script_lines):
    return script_lines

async def _handle_exact_command(line, script_lines):
    if line == "RANDOM_LOWERCASE_LETTER":
        sendString(random.choice(letters))
    elif line == "RANDOM_UPPERCASE_LETTER":
        sendString(random.choice(letters.upper()))
    elif line == "RANDOM_LETTER":
        sendString(random.choice(letters + letters.upper()))
    elif line == "RANDOM_NUMBER":
        sendString(random.choice(numbers))
    elif line == "RANDOM_SPECIAL":
        sendString(random.choice(specialChars))
    elif line == "RANDOM_CHAR":
        sendString(random.choice(letters + letters.upper() + numbers + specialChars))
    elif line == "VID_RANDOM" or line == "PID_RANDOM":
        for _ in range(4):
            sendString(random.choice("0123456789ABCDEF"))
    elif line == "MAN_RANDOM" or line == "PROD_RANDOM":
        for _ in range(12):
            sendString(random.choice(letters + letters.upper() + numbers))
    elif line == "SERIAL_RANDOM":
        for _ in range(12):
            sendString(random.choice(letters + letters.upper() + numbers + specialChars))
    elif line == "RESET":
        kbd.release_all()
    elif line == "SAVE_HOST_KEYBOARD_LOCK_STATE":
        SaveKeyboardLedState()
    elif line == "RESTORE_HOST_KEYBOARD_LOCK_STATE":
        RestoreKeyboardLedState()
    elif line == "WAIT_FOR_SCROLL_CHANGE":
        last_scroll_state = _scrollOn()
        while True:
            current_scroll_state = _scrollOn()
            if current_scroll_state != last_scroll_state:
                break
            await asyncio.sleep(0.01)
    else:
        return None
    return script_lines

async def parseLine(line, script_lines):
    global defaultDelay, variables, functions, defines
    line = line.strip()
    line = line.replace("$_RANDOM_INT", str(random.randint(int(variables.get("$_RANDOM_MIN", 0)), int(variables.get("$_RANDOM_MAX", 65535)))))
    line = replaceDefines(line)
    prefix_handlers = [
        ("INJECT_MOD", _handle_inject_mod),
        ("REM_BLOCK", _handle_rem_block),
        ("REM", _handle_rem),
        ("HOLD", _handle_hold),
        ("RELEASE", _handle_release),
        ("DELAY", _handle_delay),
        ("STRINGLN", _handle_stringln),
        ("STRING", _handle_string),
        ("PRINT", _handle_print),
        ("IMPORT", _handle_import),
        ("DEFAULT_DELAY", _handle_default_delay),
        ("DEFAULTDELAY", _handle_default_delay),
        ("LED_OFF", _handle_led_off),
        ("LED_R", _handle_led_on),
        ("LED_G", _handle_led_on),
        ("LED", _handle_led),
        ("WAIT_FOR_BUTTON_PRESS", _handle_wait_for_button_press),
        ("VAR", _handle_var),
        ("DEFINE", _handle_define),
        ("FUNCTION", _handle_function),
        ("WHILE", _handle_while),
    ]

    for prefix, handler in prefix_handlers:
        if line.startswith(prefix):
            return await handler(line, script_lines)

    if line.startswith("$"):
        return await _handle_variable_update(line, script_lines)

    if line.upper().startswith("IF"):
        return await _handle_if(line, script_lines)

    if line.upper().startswith("END_IF"):
        return await _handle_end_if(line, script_lines)

    exact_handler_result = await _handle_exact_command(line, script_lines)
    if exact_handler_result is not None:
        return exact_handler_result

    if line in functions:
        updated_lines = []
        inside_while_block = False
        for func_line in functions[line]:
            if func_line.startswith("WHILE"):
                inside_while_block = True  # Start skipping lines
                updated_lines.append(func_line)
            elif func_line.startswith("END_WHILE"):
                inside_while_block = False  # Stop skipping lines
                updated_lines.append(func_line)
                parseLine(updated_lines[0], iter(updated_lines))
                updated_lines = []  # Clear updated_lines after parsing
            elif inside_while_block:
                updated_lines.append(func_line)
            elif not (func_line.startswith("END_WHILE") or func_line.startswith("WHILE")):
                parseLine(func_line, iter(functions[line]))
    else:
        runScriptLine(line)
    
    return(script_lines)

kbd = Keyboard(usb_hid.devices)
consumerControl = ConsumerControl(usb_hid.devices)
layout = KeyboardLayout(kbd)



def getProgrammingStatus():
    # see setup mode for instructions
    progStatus = not progStatusPin.value
    return(progStatus)


defaultDelay = 0

async def runScript(file):
    global defaultDelay

    duckyScriptPath = file
    restart = True
    try:
        while restart:
            restart = False
            with open(duckyScriptPath, "r", encoding='utf-8') as f:
                script_lines = iter(f.readlines())
                previousLine = ""
                for line in script_lines:
                    print(f"runScript: {line}")
                    if(line[0:6] == "REPEAT"):
                        for i in range(int(line[7:])):
                            #repeat the last command
                            parseLine(previousLine, script_lines)
                            await asyncio.sleep(float(defaultDelay) / 1000)
                    elif line.startswith("RESTART_PAYLOAD"):
                        restart = True
                        break
                    elif line.startswith("STOP_PAYLOAD"):
                        restart = False
                        break
                    else:
                        await parseLine(line, script_lines)
                        previousLine = line
                    await asyncio.sleep(float(defaultDelay) / 1000)
    except OSError as e:
        print("Unable to open file", file)

def selectPayload():
    global payload1Pin, payload2Pin, payload3Pin, payload4Pin
    payload = "payload.dd"
    # check switch status
    payload1State = not payload1Pin.value
    payload2State = not payload2Pin.value
    payload3State = not payload3Pin.value
    payload4State = not payload4Pin.value

    if(payload1State == True):
        payload = "payload.dd"

    elif(payload2State == True):
        payload = "payload2.dd"

    elif(payload3State == True):
        payload = "payload3.dd"

    elif(payload4State == True):
        payload = "payload4.dd"

    else:
        # if all pins are high, then no switch is present
        # default to payload1
        payload = "payload.dd"

    return payload

async def blink_led(led):
    print("Blink")
    if(board.board_id == 'raspberry_pi_pico' or board.board_id == 'raspberry_pi_pico2'):
        blink_pico_led(led)
    elif(board.board_id == 'raspberry_pi_pico_w' or board.board_id == 'raspberry_pi_pico2_w'):
        blink_pico_w_led(led)


async def blink_pico_led(led):
    print("starting blink_pico_led")
    led_state = False
    while True:
        if(variables.get("$_EXFIL_LEDS_ENABLED")):
            led.duty_cycle = 65535
        else:
            if led_state:
                #led_pwm_up(led)
                #print("led up")
                for i in range(100):
                    # PWM LED up and down
                    if i < 50:
                        led.duty_cycle = int(i * 2 * 65535 / 100)  # Up
                    await asyncio.sleep(0.01)
                led_state = False
            else:
                #led_pwm_down(led)
                #print("led down")
                for i in range(100):
                    # PWM LED up and down
                    if i >= 50:
                        led.duty_cycle = 65535 - int((i - 50) * 2 * 65535 / 100)  # Down
                    await asyncio.sleep(0.01)
                led_state = True
        await asyncio.sleep(0)

async def blink_pico_w_led(led):
    print("starting blink_pico_w_led")
    led_state = False
    while True:
        if(variables.get("$_EXFIL_LEDS_ENABLED")):
            led.value = 1
        else: 
            if led_state:
                #print("led on")
                led.value = 1
                await asyncio.sleep(0.5)
                led_state = False
            else:
                #print("led off")
                led.value = 0
                await asyncio.sleep(0.5)
                led_state = True
            await asyncio.sleep(0.5)


async def monitor_buttons(button1):
    global inBlinkeyMode, inMenu, enableRandomBeep, enableSirenMode,pixel
    print("starting monitor_buttons")
    button1Down = False
    while True:
        button1.update()

        button1Pushed = button1.fell
        button1Released = button1.rose
        button1Held = not button1.value

        if(button1Pushed):
            print("Button 1 pushed")
            button1Down = True
        if(button1Released):
            print("Button 1 released")
            if(button1Down):
                print("push and released")

        if(button1Released):
            if(button1Down):
                # Run selected payload
                payload = selectPayload()
                print("Running ", payload)
                await runScript(payload)
                print("Done")
            button1Down = False

        await asyncio.sleep(0)

async def monitor_led_changes():
    print("starting monitor_led_changes")

    while True:
        if variables.get("$_EXFIL_MODE_ENABLED"):
            try:
                bit_list = []
                last_caps_state = _capsOn()
                last_num_state = _numOn()
                last_scroll_state = _scrollOn()

                with open("loot.bin", "ab") as file:
                    while variables.get("$_EXFIL_MODE_ENABLED"):
                        caps_state = _capsOn()
                        num_state = _numOn()
                        scroll_state = _scrollOn()

                        if caps_state != last_caps_state:
                            bit_list.append(0)
                            last_caps_state = caps_state 

                        elif num_state != last_num_state:
                            bit_list.append(1)
                            last_num_state = num_state

                        if len(bit_list) == 8:
                            byte = 0
                            for b in bit_list:
                                byte = (byte << 1) | b
                            file.write(bytes([byte]))
                            bit_list = []

                        if scroll_state != last_scroll_state:
                            variables["$_EXFIL_LEDS_ENABLED"] = False
                            break            
                        
                        await asyncio.sleep(0.001)
            except Exception as e:
                print(f"Error occurred: {e}")

        await asyncio.sleep(0.0)

