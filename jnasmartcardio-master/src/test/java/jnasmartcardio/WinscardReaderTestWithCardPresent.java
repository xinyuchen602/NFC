/*
 * To the extent possible under law, contributors have waived all
 * copyright and related or neighboring rights to work.
 */
package jnasmartcardio;
import static org.junit.Assert.*;


import java.security.Security;
import java.util.List;

import javax.smartcardio.ATR;
import javax.smartcardio.Card;
import javax.smartcardio.CardChannel;
import javax.smartcardio.CardException;
import javax.smartcardio.CardTerminal;
import javax.smartcardio.CardTerminals;
import javax.smartcardio.CommandAPDU;
import javax.smartcardio.ResponseAPDU;
import javax.smartcardio.TerminalFactory;


import org.junit.After;
import org.junit.Before;
import org.junit.Test;

/** Plug your card terminal in and insert your card before running this test. */
public class WinscardReaderTestWithCardPresent{
        
	TerminalFactory context;
	private CardTerminals terminals;
	@Before public void setUp() throws Exception {
            
		if (true) {
                    System.setProperty("sun.security.smartcardio.library", "/System/Library/Frameworks/PCSC.framework/Versions/Current/PCSC");
			context = TerminalFactory.getInstance("PC/SC", null);
			terminals = context.terminals();
		} else {
			TerminalFactory terminalFactory = TerminalFactory.getDefault();
			terminals = terminalFactory.terminals();
		}
	}
	@After public void tearDown() throws CardException {
		context = null;
		System.gc(); // not entirely sure if this will immediately dispose() the TerminalFactory
	}
	@Test
	public void testList() throws CardException {
		List<CardTerminal> terminalList = terminals.list();
		assertEquals(1, terminalList.size());
		CardTerminal terminal = terminalList.get(0);
		String name = terminal.getName();
		assertTrue(0 != name.length());
		boolean isCardPresent = terminal.isCardPresent();
		assertTrue(isCardPresent);
	}
	@Test public void testGetAtr() throws CardException {
		List<CardTerminal> terminalList = terminals.list();
		CardTerminal terminal = terminalList.get(0);
		Card connection = terminal.connect("*");
		ATR atr = connection.getATR();
		byte[] atrBytes = atr.getBytes();
		assertNotSame(0, atrBytes.length);
		boolean hasNonZeroAtr = false;
		for (int i = 0; i < atrBytes.length; i++) {
			hasNonZeroAtr = hasNonZeroAtr || atrBytes[i] != 0;
		}
		assertTrue(hasNonZeroAtr);
	}
	@Test public void testTransmit() throws CardException {
		List<CardTerminal> terminalList = terminals.list();
		CardTerminal terminal = terminalList.get(0);
		Card connection = terminal.connect("*");
		CardChannel channel = connection.getBasicChannel();
		assertEquals(0, channel.getChannelNumber());
		ResponseAPDU response = channel.transmit(new CommandAPDU(0x00, 0xa4, 0x00, 0x00, 0));
		int sw = response.getSW();
		assertEquals(String.format("got response 0x%04x instead of 0x9000, %s", sw, response), 0x9000, sw);
	}
}
