<?xml version="1.0" encoding="UTF-8"?>

<!--
    *  Copyright (C) 2008
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

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    xmlns:om="http://www.openmath.org/OpenMath"
    xmlns:cdg="http://www.openmath.org/OpenMathCDG"
    xmlns:m="http://www.w3.org/1998/Math/MathML"
    xmlns:xd="http://www.pnp-software.com/XSLTdoc"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="#all"
    version="2.0">
    <!-- Render OpenMath to Content MathML -->
    <xsl:import href="openmath/om2cmml.xsl"/>
    <!-- Render OpenMath to Popcorn -->
    <xsl:import href="openmath/omobj2popcorn.xsl"/>

    <xd:doc type="stylesheet">A collection of utility functions for <a href="http://www.openmath.org">OpenMath</a> symbols and objects
	<xd:author>Christoph Lange</xd:author>
	<xd:copyright>Christoph Lange, 2008</xd:copyright>
	<xd:svnId>$Id$</xd:svnId>
    </xd:doc>

    <xsl:include href="openmath-uris.xsl"/>
    <xsl:include href="ntn.xsl"/>
</xsl:stylesheet>

<!--
Local Variables:
mode: nxml
nxml-child-indent: 4
End:
-->

