//
//  GLADPriv.hpp
//  GLAD
//
//  Created by van Liempt, Jordi on 27.04.22.
//  Copyright © 2022 Ken Arroyo Ohori. All rights reserved.
//

/* The classes below are not exported */
#pragma GCC visibility push(hidden)

class GLADPriv
{
    public:
    void HelloWorldPriv(const char *);
};

#pragma GCC visibility pop
