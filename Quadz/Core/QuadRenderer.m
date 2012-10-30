//
//  QuadRenderer.m
//  Quadz
//
//  Created by Dirk Zimmermann on 10/28/12.
//  Copyright (c) 2012 Dirk Zimmermann. All rights reserved.
//

#import "QuadRenderer.h"

#import "QuadArray.h"
#import "DLog.h"

typedef struct {
    GLfloat position[2];
    GLubyte color[4];
} vertex_t;

typedef GLushort QuadRendererIndexType;

static inline vertex_t VertexMakeWithColorPointer(GLfloat x, GLfloat y, GLubyte *color)
{
    vertex_t v = { x, y, color[0], color[1], color[2], color[3] };
    return v;
}

@interface QuadRenderer ()

@property (nonatomic, strong) QuadArray *quads;

@end

@implementation QuadRenderer
{
    /** the last vertex buffer we rendered in */
    vertex_t *_vertices;

    /** index buffer */
    GLushort *_indices;

    /** the last number of vertices rendered into @see _vertices */
    size_t _numberOfVertices;

    /** set to YES once the vertex arrays and vertex buffer objects were initialized */
    BOOL _setup;

    GLuint _vertexArray;
    GLuint _vertexBuffer;
    GLuint _indexBuffer;
    GLuint _lastIndex;
}

- (id)init
{
    self = [super init];
    if (self) {
        _quads = [[QuadArray alloc] init];
    }
    return self;
}

- (void)dealloc
{
    glDeleteBuffers(1, &_vertexBuffer);
    glDeleteVertexArraysOES(1, &_vertexArray);

    if (_vertices) {
        free(_vertices);
    }
}

- (void)renderQuadArray:(QuadArray *)quads vertexBuffer:(vertex_t *)vertexBuffer indexBuffer:(GLushort *)indexBuffer
{
    _lastIndex = 0;
    vertex_t *vertex = vertexBuffer;
    GLushort *index = indexBuffer;
    for (size_t i = 0; i < quads.count; ++i) {
        Quad quad = [quads elementAt:i];

        CGFloat halfWidth = ((GLfloat) quad.width)/2;
        CGFloat halfHeight = ((GLfloat) quad.height)/2;

        // produce degenerate triangle to move to next quad position
        if (i > 0) {
            *index++ = _lastIndex-1;
            *index++ = _lastIndex;
        }

        // bottom left
        *vertex++ = VertexMakeWithColorPointer(QuadX(quad) - halfWidth, QuadY(quad) - halfHeight,
                                               QuadColor(&quad));
        *index++ = _lastIndex++;

        // bottom right
        *vertex++ = VertexMakeWithColorPointer(QuadX(quad) + halfWidth, QuadY(quad) - halfHeight,
                                               QuadColor(&quad));
        *index++ = _lastIndex++;

        // top left
        *vertex++ = VertexMakeWithColorPointer(QuadX(quad) - halfWidth, QuadY(quad) + halfHeight,
                                               QuadColor(&quad));
        *index++ = _lastIndex++;

        // top right
        *vertex++ = VertexMakeWithColorPointer(QuadX(quad) + halfWidth, QuadY(quad) + halfHeight,
                                               QuadColor(&quad));
        *index++ = _lastIndex++;
    }
}

- (void)renderQuadArray:(QuadArray *)quads
{
    if (quads.count > 0) {
        // 4 vertices per quad, plus 2 vertices for degenerate triangles in between
        size_t newNumberOfVertices = quads.count * 4 + (quads.count-1) * 2;
        if (newNumberOfVertices != _numberOfVertices) {
            _numberOfVertices = newNumberOfVertices;
            _vertices = realloc(_vertices, _numberOfVertices * sizeof(vertex_t));
            _indices = realloc(_indices, _numberOfVertices * sizeof(GLushort));
        }
        [self renderQuadArray:quads vertexBuffer:_vertices indexBuffer:_indices];
    }
}

- (void)addQuad:(Quad)quad
{
    [self.quads addElement:quad];
}

- (void)removeAllQuads
{
    [self.quads removeAllElements];
}

- (void)bind
{
    if (!_setup) {
        glGenVertexArraysOES(1, &_vertexArray);
        glBindVertexArrayOES(_vertexArray);
        glGenBuffers(1, &_vertexBuffer);
        glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
        glGenBuffers(1, &_indexBuffer);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);

        glEnableVertexAttribArray(AttributeIndexPosition);
        glVertexAttribPointer(AttributeIndexPosition, 2, GL_FLOAT, GL_FALSE, sizeof(vertex_t),
                              (GLvoid *) offsetof(vertex_t, position));
        glEnableVertexAttribArray(AttributeIndexColor);
        glVertexAttribPointer(AttributeIndexColor, 4, GL_UNSIGNED_BYTE, GL_TRUE, sizeof(vertex_t),
                              (GLvoid *) offsetof(vertex_t, color));

        _setup = YES;
    } else {
        glBindVertexArrayOES(_vertexArray);
        glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
    }
}

- (void)draw
{
    [self renderQuadArray:self.quads];
    if (_numberOfVertices) {
        glBufferData(GL_ARRAY_BUFFER, _numberOfVertices * sizeof(vertex_t), _vertices, GL_DYNAMIC_DRAW);
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, _numberOfVertices * sizeof(GLushort), _indices, GL_DYNAMIC_DRAW);
        glDrawElements(GL_TRIANGLE_STRIP, _numberOfVertices, GL_UNSIGNED_SHORT, 0);
    }
}

@end
