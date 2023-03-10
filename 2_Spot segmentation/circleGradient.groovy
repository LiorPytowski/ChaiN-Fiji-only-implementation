#@ Integer sizeX
#@ Integer sizeY
#@ Double centerX
#@ Double centerY
#@ Double innerRadius
#@ Double outerRadius
#@ UIService ui

/**
 * Creates a circular gradient
 * 
 * see:
 * https://forum.image.sc/t/circular-gradient/78365
 * 
 * John Bogovic
 */

// the size of the image
itvl = new FinalInterval( [sizeX, sizeY ] as long[] );

// the center of the circle
center = new RealPoint( [centerX, centerY ] as double[] );


// the shape of the falloff function
falloff = new CosFalloff( center, innerRadius, outerRadius );
img = new FunctionRandomAccessible( 2, falloff, {new FloatType()} as Supplier );

// display the result
ui.show( Views.interval( img, itvl ));


/**
 * A radial function from the center.
 * Results in 1 for points within innerRadius of the center,
 * zero for points outside the outerRadius, and uses a cosine shape
 * for points in between the two radii.
 */
public class CosFalloff implements BiConsumer<Localizable,FloatType> {
	
	RealPoint center;
	double innerRadius;
	double outerRadius;
	
	public CosFalloff( RealPoint center, double innerRadius, double outerRadius ){
		this.center = center;
		this.innerRadius = innerRadius;
		this.outerRadius = outerRadius;
	}
	
	@Override
	public void accept( Localizable x, FloatType v )
	{
		double r = distance( x, center );
		if ( r <= innerRadius )
			v.setOne();
		else if ( r >= innerRadius + outerRadius ) {
			v.setZero();
		}
		else
		{
			double t = ( r - innerRadius );
			v.setReal(0.5 + 0.5 * Math.cos(t * Math.PI / outerRadius));
		}
	}
	
	def double distance( RealLocalizable p, RealLocalizable q )
	{
		double dist = 0;
		int n = p.numDimensions();
		for ( int d = 0; d < n; ++d ) {
			double diff = q.getDoublePosition( d ) - p.getDoublePosition( d );
			dist += diff * diff;
		}
		return Math.sqrt(dist);
	}
}

import java.util.function.Supplier;
import java.util.function.BiConsumer;

import net.imglib2.FinalInterval;
import net.imglib2.Localizable;
import net.imglib2.RealLocalizable;
import net.imglib2.RealPoint;
import net.imglib2.Point;
import net.imglib2.view.Views;
import net.imglib2.position.FunctionRandomAccessible;
import net.imglib2.type.numeric.real.FloatType;