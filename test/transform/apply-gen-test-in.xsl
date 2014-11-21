<?xml version="1.0" encoding="utf-8"?>
<!--
  Stub stylesheet for apply-gen testing

  Copyright (C) 2014 LoVullo Associates, Inc.

    This file is part of hoxsl.

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
-->

<stylesheet version="2.0"
  xmlns="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:foo="http://www.lovullo.com/_junk">


  <function name="foo:add-two" as="xs:decimal">
    <param name="x" as="xs:decimal" />
    <param name="y" as="xs:decimal" />

    <sequence select="$x + $y" />
  </function>
</stylesheet>
