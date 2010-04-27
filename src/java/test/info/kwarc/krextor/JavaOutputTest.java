/*  Copyright (C) 2010
 *  Christoph Lange
 *  KWARC, Jacobs University Bremen
 *  http://kwarc.info/projects/krextor/
 *
 *   Krextor is free software; you can redistribute it and/or
 *   modify it under the terms of the GNU Lesser General Public
 *   License as published by the Free Software Foundation; either
 *   version 2 of the License, or (at your option) any later version.
 *   
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *   Lesser General Public License for more details.
 *   
 *   You should have received a copy of the GNU Lesser General Public
 *   License along with this library; if not, write to the
 *   Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 *   Boston, MA 02111-1307, USA.
 */
package info.kwarc.krextor;

import java.io.IOException;

import nu.xom.Builder;
import nu.xom.ParsingException;

import org.junit.Assert;
import org.junit.Test;

/**
 * Test Java output
 */
public class JavaOutputTest {
    @Test
    public void testSimpleTriple()
            throws ParsingException, IOException, KrextorException {
        Krextor k = new Krextor();

        // trick to get a value from the callback method
        final String[] result = new String[1];

        // run the extraction (always returns the same dummy triple)
        k.extract("test",
                new Builder().build(TestUtils.getTestFile("dummy.xml")),
                new TripleAdder() {
            public void addTriple(
                    String subject,
                    String subjectType,
                    String predicate,
                    String object,
                    String objectType,
                    String objectLanguage,
                    String objectDatatype) {
                result[0] = subject; 
            }
        });
        Assert.assertEquals(result[0], "http://kwarc.info/projects/krextor/test#subject");
    }
}
