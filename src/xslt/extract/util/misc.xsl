<?xml version="1.0" encoding="UTF-8"?>

<!--
    *  Copyright (C) 2010
    *  Christoph Lange
    *  KWARC, Jacobs University Bremen
    *  http://kwarc.info/projects/krextor/
    *
    *   Krextor is free software; you can redistribute it and/or
    * 	modify it under the terms of the GNU Lesser General Public
    * 	License as published by the Free Software Foundation; either
    * 	version 2 of the License, or (at your option) any later version.
    *
    * 	This program is distributed in the hope that it will be useful,
    * 	but WITHOUT ANY WARRANTY; without even the implied warranty of
    * 	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    * 	Lesser General Public License for more details.
    *
    * 	You should have received a copy of the GNU Lesser General Public
    * 	License along with this library; if not, write to the
    * 	Free Software Foundation, Inc., 59 Temple Place - Suite 330,
    * 	Boston, MA 02111-1307, USA.
    * 
-->

<stylesheet xmlns="http://www.w3.org/1999/XSL/Transform" 
    xmlns:xd="http://www.pnp-software.com/XSLTdoc"
    xmlns:krextor="http://kwarc.info/projects/krextor"
    exclude-result-prefixes="#all"
    version="2.0">
  <xd:doc type="stylesheet">A collection of miscellaneous utility functions
	<xd:author>Christoph Lange</xd:author>
	<xd:copyright>Christoph Lange, 2010</xd:copyright>
	<xd:svnId>$Id$</xd:svnId>
    </xd:doc>


    <xd:doc>Transforms e.g. false-conjecture → FalseConjecture</xd:doc>
    <function name="krextor:dashes-to-camelcase">
	<param name="type"/>
	<variable name="capitalized-tokens">
	    <for-each select="tokenize($type, '-')">
		<analyze-string select="." regex="^(.)">
		    <matching-substring>
			<value-of select="upper-case(regex-group(1))"/>
		    </matching-substring>
		    <non-matching-substring>
			<value-of select="."/>
		    </non-matching-substring>
		</analyze-string>
	    </for-each>
	</variable>
	<value-of select="string-join($capitalized-tokens, '')"/>
    </function>
</stylesheet>
